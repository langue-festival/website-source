#!/bin/bash

js_output_file="./build/compiled_pages.js"

function page_to_pair {
    path_name="$1"
    file_name="$(basename "${path_name}")"
    page_name="${file_name%.*}"
    page_content="$(cat "${path_name}" | sed 's/"/\\"/g')"
    page_content="$(echo "${page_content}" | awk '{ printf $0 "\\n" }')"

    echo "    [\"${page_name}\", \"${page_content}\"]"
}

function get_pages {
    last_file=""

    for file in pages/*; do
        if [ -n "${last_file}" ]; then
            echo "$(page_to_pair "${last_file}"),"
        fi

        last_file="${file}"
    done

    if [ -n "${last_file}" ]; then
        echo "$(page_to_pair "${last_file}")"
    fi
}

test -d  build || mkdir build

echo "var pages = [" > "${js_output_file}"
get_pages >> "${js_output_file}"
echo "];" >> "${js_output_file}"
