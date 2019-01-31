#!/usr/bin/env python3

# Temporary hacky helper script. Glues together the caasp-vmware tool and download-image
# TODO move this into testrunner

# The script is run from the automation directory

from subprocess import check_output
from urllib.parse import urljoin, urlsplit
import glob
import re
import subprocess

import requests
from lxml import html

def pick_file_urls(list_url, fn_pattern):
    """Scan a list of files

    :returns: [(url, fname), ...]
    """
    print("Fetching %r" % list_url)
    r = requests.get(list_url)
    tree = html.fromstring(r.text)
    links = tree.xpath('//a/text()')
    regexp = re.compile(fn_pattern)

    out = []
    for l in links:
        matches = regexp.match(l)
        if matches:
            url = urljoin(list_url, matches.string)
            if list_url.endswith('/'):
                url = list_url + matches.string
            else:
                url = list_url + '/' + matches.string
            out.append((url, matches.string))

    if not out:
        raise Exception("No links found on %r" % list_url)

    return out

def fetch_images_in_vsphere():
    lines = check_output(
        "cd caasp-vmware && ./caasp-vmware --vc-host jazz.qa.prv.suse.net --media-dir caasp-team listimages",
        shell=True
    )
    lines = lines.decode()
    print("--")
    print(lines)
    print("--")

    i = lines.find('available vmdk:\n')
    lines = lines[i+16:]
    r = re.compile('SUSE-CaaSP-.*vmdk$')
    out = set()
    for l in lines.splitlines():
        m = r.search(l)
        if m:
            out.add(m.group(0))

    return out


def scan_downloaded_images():
    return set(glob.glob('SUSE-CaaSP*.vmdk'))


def upload_image_to_vsphere(fn):
    cmd = "./caasp-vmware --vc-host jazz.qa.prv.suse.net  --media-dir caasp-team  --source-media ../{} pushimage".format(fn)
    lines = check_output(
        "cd caasp-vmware && " + cmd,
        shell=True
    )
    lines = lines.decode()
    print("--")
    print(lines)
    print("--")

def save_img_filename(fn):
    with open('vmware_img_name', 'w') as f:
        f.write(fn)

def delete_image_in_vsphere(fn):
    print("Purging old image from vSphere: %s" % fn)
    cmd = "./caasp-vmware --vc-host jazz.qa.prv.suse.net  --media-dir caasp-team  --media {} deleteimage".format(fn)
    lines = check_output(
        "cd caasp-vmware && " + cmd,
        shell=True
    )
    lines = lines.decode()
    print("--")
    print(lines)
    print("--")

def main():
    list_url = "http://download.suse.de/ibs/Devel:/CASP:/Head:/ControllerNode/images-sle15"
    regex = 'SUSE-CaaSP-4.0.*CaaSP-Stack-VMware.*\\.vmdk$'
    available_images = pick_file_urls(list_url, regex)
    vsphere_fnames = fetch_images_in_vsphere()
    available_fnames = set(fn for url, fn in available_images)
    old_fnames_on_vsphere = vsphere_fnames - available_fnames
    for fn in old_fnames_on_vsphere:
        delete_image_in_vsphere(fn)

    # assuming there's only one new available image most of the time, ingest it
    new_fnames = available_fnames - vsphere_fnames

    if not new_fnames:
        save_img_filename(sorted(available_fnames)[0])
        print("done - no upload needed")
        return

    subprocess.call(
        "./misc-tools/download-image  --type vmware channel://devel_15 --path .",
        shell=True
    )
    # handle race condition when fetching image
    local_fnames = scan_downloaded_images()
    if (new_fnames - local_fnames):
        print("Unexpected filenames!")
        print("Local: %s" % sorted(local_fnames))
        print("Available for download: %s" % sorted(new_fnames))
        sys.exit(1)

    if (local_fnames - new_fnames):
        print("Unexpected filenames!")
        print("Local: %s" % sorted(local_fnames))
        print("Available for download: %s" % sorted(new_fnames))
        sys.exit(1)

    fn = sorted(local_fnames)[0]
    print("Uploading %s to vSphere" % fn)
    upload_image_to_vsphere(fn)
    save_img_filename(fn)
    print("done")


if __name__ == '__main__':
    main()
