# Postcode

[![Build Status](https://github.com/alunap/Postcode.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/alunap/Postcode.jl/actions/workflows/CI.yml?query=branch%3Amain)

A simple Julia package to enable lookup of postcodes in numerous countries based on the files provided at https://download.geonames.org.

This is inspired by the python library pgeocodes, but does not attempt to match the API or functionality of that library. In particular, if the postcode is in Canada, UK, or Netherlands this package downloads the alternative file to allow more precise position data from the full postcode.