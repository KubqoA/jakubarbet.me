#!/bin/sh

set -e

bun run build
tar -czvf new.tar.gz dist
echo "put new.tar.gz ./jakubarbet.me/" | sftp jakub@jakubarbet.me
echo "rm -Rf ~/jakubarbet.me/dist && tar -xzvf ~/jakubarbet.me/new.tar.gz -C ~/jakubarbet.me && rm -Rf ~/jakubarbet.me/public_html && mv ~/jakubarbet.me/{dist,public_html} && rm ~/jakubarbet.me/new.tar.gz" | ssh jakub@jakubarbet.me
rm new.tar.gz
echo "Deployed new version"

