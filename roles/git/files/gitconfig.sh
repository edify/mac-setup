#!/bin/bash

git config --global user.name "$(finger `whoami` | awk -F: '{ print $3 }' | head -n1 | sed 's/^ //')"
git config --global user.email "$(finger `whoami` | awk -F: '{ print $3 }' | head -n1 | sed 's/^ //' | sed 's/ /\./' | awk '{print tolower($0)"@edify.cr"}')"