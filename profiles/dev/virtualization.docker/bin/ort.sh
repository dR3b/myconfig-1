#!/usr/bin/env bash
# Copyright 2019 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT

#
# A simple script which generates the ort docker image on demand and wraps calls
# to ort into a docker layer
#
# Based on Code from https://github.com/heremaps/oss-review-toolkit (Licensed under Apache-2.0)
#

set -e

DEBUG_LEVEL="--info"
case $1 in
    "--no-debug") shift; DEBUG_LEVEL="" ;;
    "--info") shift; ;;
    "--debug") shift; DEBUG_LEVEL="--debug"; set -x ;;
esac

helpMsg() {
    cat<<EOF
usage:
  $0 --all <folder>
  $0 --analyze <folder>
  $0 --download <yaml>
  $0 --scan <yaml>
  $0 --report <yaml>
  $0 [args]
  $0 --help

Builds the ort image on demand.
Remove the ort:latest image to enforce rebuild of the docker image.
EOF
}

#################################################################################
# function to build ort docker image
#################################################################################
buildImageIfMissing() {
    if [[ "$(docker images -q ort:latest 2> /dev/null)" == "" ]]; then
        ORT=$(mktemp -d)
        trap 'rm -rf $ORT' EXIT
        git clone https://github.com/heremaps/oss-review-toolkit/ $ORT

        docker build -t ort-build:latest - < $ORT/docker/build/Dockerfile

        docker run -i --rm \
               -v "$ORT":/workdir \
               -u $(id -u $USER):$(id -g $USER) \
               -w /workdir \
               --net=host \
               ort-build \
               ./gradlew --no-daemon --stacktrace :cli:installDist :cli:distTar

        ORT_VERSION=$(cat $ORT/model/src/main/resources/VERSION)
        docker build \
               --build-arg ORT_VERSION=$ORT_VERSION \
               -t ort:latest \
               -f $ORT/docker/run/Dockerfile $ORT/cli/build/distributions
        docker tag ort:latest ort:"${ORT_VERSION//[+]/-}"
    else
        echo "docker image already build"
    fi
}

#################################################################################
# function to run dockerized ort commands
#################################################################################
prepareDotOrt() {
    declare -a types=("analyzer" "downloader" "scanner" )
    for type in ${types[@]}; do
        mkdir -p "$HOME/.ort/dockerHome/.ort/$type"
        if [[ ! -e "$HOME/.ort/$type" ]]; then
            ln -s "$HOME/.ort/dockerHome/.ort/$type" "$HOME/.ort/$type"
        fi
    done
}

getOutFolder() {
    local workdir="$(readlink -f "$1")"
    local out="${workdir%_ort}_ort"
    mkdir -p "$out"
    echo "$out"
}

runOrt() {
    local workdir="$(readlink -f "$1")"
    [[ ! -d "$workdir" ]] && exit 1
    shift

    prepareDotOrt

    (set -x;
     docker run -i \
            --rm \
            -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro -u $(id -u $USER):$(id -g $USER) \
            -v "$HOME/.ort/dockerHome":"$HOME" \
            -v "$workdir":/workdir -v "$(getOutFolder "$workdir")":/out \
            -w /workdir \
            --net=host \
            ort --info \
            $@;
     times
     )
}

#################################################################################
# actual calls to ort features
#################################################################################
analyzeFolder() {
    local folderToScan="$(readlink -f "$1")"
    [[ ! -d "$folderToScan" ]] && exit 1

    printf "\n\n\nanalyze: $folderToScan\n\n"

    local logfile="$(getOutFolder "$folderToScan")/analyzer.logfile"
    runOrt "$folderToScan" \
           analyze -i /workdir --output-dir /out |
        tee "$logfile"
}

downloadSource() {
    local analyzeResult="$(readlink -f "$1")"
    [[ ! -f "$analyzeResult" ]] && exit 1

    local analyzeResultFolder="$(dirname $analyzeResult)"
    local analyzeResultFile="$(basename $1)"
    local logfile="$(getOutFolder "$analyzeResultFolder")/downloader.logfile"
    runOrt "$analyzeResultFolder" \
           download --ort-file "$analyzeResultFile" --output-dir /out |
        tee "$logfile"
}

scanAnalyzeResult() {
    local analyzeResult="$(readlink -f "$1")"
    [[ ! -f "$analyzeResult" ]] && exit 1

    printf "\n\n\nscan: $analyzeResult\n\n"

    local analyzeResultFolder="$(dirname $analyzeResult)"
    local analyzeResultFile="$(basename $1)"
    local logfile="$(getOutFolder "$analyzeResultFolder")/scanner.logfile"
    runOrt "$analyzeResultFolder" \
           scan --ort-file "$analyzeResultFile" --output-dir /out |
        tee "$logfile"
}

reportScanResult() {
    local scanResult="$(readlink -f "$1")"
    [[ ! -f "$scanResult" ]] && exit 1

    printf "\n\n\nreport: $scanResult\n\n"

    local scanResultFolder="$(dirname $scanResult)"
    local scanResultFile="$(basename $1)"
    local logfile="$(getOutFolder "$scanResultFolder")/reporter.logfile"
    runOrt "$scanResultFolder" \
           report -f StaticHtml,Notice,Excel,WebApp --ort-file "$scanResultFile" --output-dir /out |
        tee "$logfile"
}

doAll() {
    local folderToScan="$1"
    [[ ! -d "$folderToScan" ]] && exit 1

    local outFolder=$(getOutFolder "$folderToScan")

    local reportResult="$outFolder/scan-report-web-app.html"
    if [[ ! -f "$reportResult" ]]; then
        local scanResult="$outFolder/scan-result.yml"
        if [[ ! -f "$scanResult" ]]; then
            local analyzeResult="$outFolder/analyzer-result.yml"
            if [[ ! -f "$analyzeResult" ]]; then
                analyzeFolder "$folderToScan"
            else
                echo "skip analyze ..."
            fi
            scanAnalyzeResult "$analyzeResult"
        else
            echo "skip scan ..."
        fi
        reportScanResult "$scanResult"
    else
        echo "skip report ..."
    fi
}

#################################################################################
# main
#################################################################################
buildImageIfMissing
case $1 in
    "--all") shift; doAll "$@" ;;
    "--analyze") shift; analyzeFolder "$@" ;;
    "--download") shift; downloadSource "$@" ;;
    "--scan") shift; scanAnalyzeResult "$@" ;;
    "--report") shift; reportScanResult "$@" ;;
    "--ortHelp") shift; ortHelp ;;
    "--help") helpMsg ;;
    *) runOrt "$(pwd)" "$@" ;;
esac
times
