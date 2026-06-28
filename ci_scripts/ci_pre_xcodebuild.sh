#!/bin/sh

# Xcode Cloud — fija el build number (CFBundleVersion) con el número de build
# que asigna Xcode Cloud, de forma monótona y única en cada subida a TestFlight.
# Requiere VERSIONING_SYSTEM = apple-generic en el proyecto.

set -e

if [ -z "$CI_BUILD_NUMBER" ]; then
    echo "CI_BUILD_NUMBER no definido — se omite el bump de build number."
    exit 0
fi

# El build number solo importa en la acción 'archive' (la que se sube a TestFlight /
# App Store). En las acciones de test ('build-for-testing' / 'test-without-building')
# agvtool falla y tumbaba el workflow Default, que ahora solo testea. Valores posibles
# de CI_XCODEBUILD_ACTION: analyze, archive, build, build-for-testing, test-without-building.
if [ "$CI_XCODEBUILD_ACTION" != "archive" ]; then
    echo "Acción '$CI_XCODEBUILD_ACTION' (no archive) — se omite el bump de build number."
    exit 0
fi

# La raíz del repo (donde está el .xcodeproj) es el repositorio primario.
cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "Fijando build number a $CI_BUILD_NUMBER"
agvtool new-version -all "$CI_BUILD_NUMBER"
