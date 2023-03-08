#!/usr/bin/env python3
# -*- coding:utf-8 -*-

# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (C) 2022-2023 xqyjlj<xqyjlj@126.com>
#
# @author      xqyjlj
# @file        build.py
#
# Change Logs:
# Date           Author       Notes
# ------------   ----------   -----------------------------------------------
# 2023-03-02     xqyjlj       initial version
#

import yaml
import os, sys, getopt, datetime, subprocess
import hashlib
import shutil
from github import Github, GithubException


def build_chips_repository(directory):
    repository_header = f"""# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (C) 2022-2023 xqyjlj<xqyjlj@126.com>
#
# @author      xqyjlj
# @file        repository.yml
#
# Change Logs:
# Date           Author       Notes
# ------------   ----------   -----------------------------------------------
# {datetime.date.today()}     csplinkbot   auto update
#

"""
    repository_file_path = f"{os.path.dirname(__file__)}/../../db/chips/repository.yml"
    if not os.path.exists(f"{os.path.dirname(repository_file_path)}"):
        os.makedirs(f"{os.path.dirname(repository_file_path)}")

    string = ""
    if not os.path.exists(f"{repository_file_path}"):
        repository_config = {}
    else:
        with open(repository_file_path, "r", encoding='utf-8') as fp:
            string = fp.read()
        repository_config = yaml.load(string, Loader=yaml.FullLoader)
    dump = yaml.dump(repository_config, sort_keys=True, allow_unicode=True, encoding='utf-8')
    sha256_before = hashlib.sha256(dump).hexdigest()
    if not bool(repository_config):
        repository_config = {}
    dirs = os.listdir(directory)
    for d in dirs:
        path = f"{directory}/{d}/repository.yml"
        if os.path.exists(path) and os.path.isfile(path):

            string = ""
            with open(path, "r", encoding='utf-8') as fp:
                string = fp.read()
            config = yaml.load(string, Loader=yaml.FullLoader)

            for (company_name, company_config) in config.items():
                for (series_name, series_config) in company_config.items():
                    for (line_name, line_config) in series_config.items():
                        for (chip_name, chip_config) in line_config.items():
                            if company_name in repository_config.keys():
                                if series_name in repository_config[company_name].keys():
                                    if line_name in repository_config[company_name][series_name].keys():
                                        repository_config[company_name][series_name][line_name][chip_name] = chip_config
                                    else:
                                        repository_config[company_name][series_name][line_name] = line_config
                                else:
                                    repository_config[company_name][series_name] = series_config
                            else:
                                repository_config[company_name] = company_config
    dump = yaml.dump(repository_config, sort_keys=True, allow_unicode=True, encoding='utf-8')
    if hashlib.sha256(dump).hexdigest() == sha256_before:
        print("repository.yml is not changed, so ignore it.")
        return
    with open(repository_file_path, "w", encoding="utf-8") as fp:
        fp.write(repository_header)
        fp.write(dump.decode("utf-8"))


def build_chips_chip(directory):
    dirs = os.listdir(directory)
    for d in dirs:
        path = f"{directory}/{d}/{d}.yml"
        repository_path = f"{directory}/{d}/repository.yml"

        if os.path.exists(repository_path) and os.path.isfile(repository_path):
            string = ""
            with open(path, "r", encoding='utf-8') as fp:
                string = fp.read()
            chip_config = yaml.load(string, Loader=yaml.FullLoader)
            dump = yaml.dump(chip_config, sort_keys=True, allow_unicode=True, encoding='utf-8')
            sha256_before = hashlib.sha256(dump).hexdigest()
            assert "Company" in chip_config.keys(), f"chip '{d}' has no company name."
            assert "Name" in chip_config.keys(), f"chip '{d}' has no chip name."

            company_name = chip_config["Company"].lower()
            chip_name = chip_config["Name"].lower()

            assert d == chip_name, f"chip '{d}' name is not equal to '{chip_name}'."

            chip_file_path = f"{os.path.dirname(__file__)}/../../db/chips/{company_name}/{chip_name}.yml"
            if not os.path.exists(f"{os.path.dirname(chip_file_path)}"):
                os.makedirs(f"{os.path.dirname(chip_file_path)}")

            chip_header = f"""# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (C) 2022-2023 xqyjlj<xqyjlj@126.com>
#
# @author      xqyjlj
# @file        {chip_name}.yml
#
# Change Logs:
# Date           Author       Notes
# ------------   ----------   -----------------------------------------------
# {datetime.date.today()}     csplinkbot   auto update
#

"""
            if os.path.exists(chip_file_path):
                string = ""
                with open(chip_file_path, "r", encoding='utf-8') as fp:
                    string = fp.read()
                config = yaml.load(string, Loader=yaml.FullLoader)
                dump = yaml.dump(config, sort_keys=True, allow_unicode=True, encoding='utf-8')
                if hashlib.sha256(dump).hexdigest() == sha256_before:
                    print(f"{os.path.basename(chip_file_path)} is not changed, so ignore it.")
                    return
            with open(chip_file_path, "w", encoding="utf-8") as fp:
                fp.write(chip_header)
                fp.write(yaml.dump(chip_config, sort_keys=True, allow_unicode=True, encoding='utf-8').decode("utf-8"))


def build_hal(directory):
    if not directory.endswith("config"):
        directory = f"{directory}/config"
    dirs = os.listdir(directory)
    hal = ""
    for d in dirs:
        path = f"{directory}/{d}/{d}.yml"
        repository_path = f"{directory}/{d}/repository.yml"
        if os.path.exists(repository_path) and os.path.isfile(repository_path):
            string = ""
            with open(path, "r", encoding='utf-8') as fp:
                string = fp.read()
            chip_config = yaml.load(string, Loader=yaml.FullLoader)

            assert "Company" in chip_config.keys(), f"chip '{d}' has no company name."
            assert "Name" in chip_config.keys(), f"chip '{d}' has no chip name."
            assert "HAL" in chip_config.keys(), f"chip '{d}' has no HAL name."
            hal = chip_config["HAL"]
            break
    hal_dir = f"{os.path.dirname(__file__)}/../../db/hal/{hal}"
    if os.path.exists(hal_dir):
        shutil.rmtree(hal_dir)
    if not os.path.exists(f"{os.path.dirname(__file__)}/../../db/hal/"):
        os.makedirs(f"{os.path.dirname(__file__)}/../../db/hal/")
    shutil.copytree(directory, hal_dir)
    print(hal)


def pr(branch):
    ref = os.environ.get("GITHUB_REF", None)
    if not ref:
        print("Not an event based on a push. Skipping.")
        return
    REF_PREFIX = "refs/tags/"
    if not ref.startswith(REF_PREFIX):
        print(f"Ref {ref} is not a tag. Skipping.")
        return
    tag = ref[len(REF_PREFIX):]
    github_actor = "csplinkbot"
    github_token = os.environ["GITHUB_TOKEN"]
    github_repo = "csplink/csp_repo"

    print("Connecting to GitHub...")
    github = Github(github_token)
    repo = github.get_repo(github_repo)
    try:
        br = repo.get_branch(branch="master")
        if br.name == branch:
            print(f"Branch {branch} found.")
            title = f"auto update from {branch.rstrip('-dev')}-{tag}"
            body = f"""# {title}

this pr is auto created by github ci.


                        --- by {github_actor}
"""
            repo.create_pull(title=f"auto update from {branch}", body=body, head=branch, base="master")
    except:
        print(f"Branch {branch} not found. Skipping.")


def update(directory):
    if not directory.endswith("config"):
        directory = f"{directory}/config"
    dirs = os.listdir(directory)
    hal = ""
    for d in dirs:
        path = f"{directory}/{d}/{d}.yml"
        repository_path = f"{directory}/{d}/repository.yml"
        if os.path.exists(repository_path) and os.path.isfile(repository_path):
            string = ""
            with open(path, "r", encoding='utf-8') as fp:
                string = fp.read()
            chip_config = yaml.load(string, Loader=yaml.FullLoader)

            assert "Company" in chip_config.keys(), f"chip '{d}' has no company name."
            assert "Name" in chip_config.keys(), f"chip '{d}' has no chip name."
            assert "HAL" in chip_config.keys(), f"chip '{d}' has no HAL name."
            hal = chip_config["HAL"]
            break
    pro = subprocess.Popen('git status',
                           shell=True,
                           stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE,
                           cwd=os.path.dirname(__file__))
    out, _ = pro.communicate()
    out = out.decode("utf-8")
    if "nothing to commit, working tree clean" not in out:
        subprocess.run(f"git add -A", shell=True, check=True, cwd=os.path.dirname(__file__))
        subprocess.run(f"git checkout -B {hal}-dev", shell=True, check=True, cwd=os.path.dirname(__file__))
        subprocess.run(f"git push --set-upstream origin {hal}-dev",
                       shell=True,
                       check=True,
                       cwd=os.path.dirname(__file__))
        pr(f"{hal}-dev")


def help():
    """
example:
    python ./build.py -t chips -d ~/git/github/csplink/csp_hal_apm32f1/config
    """
    print("usage: " + os.path.basename(__file__) + " [<options>] ")
    print("")
    print("    -h, --help               print this help")
    print("    -t, --type               type of build")
    print("    -d, --directory          config file directory")


if __name__ == "__main__":
    try:
        opts, args = getopt.getopt(sys.argv[1:], "ht:d:", ["help", "type=", "d="])
    except getopt.GetoptError:
        help()
        sys.exit(2)

    ty = ""
    directory = ""
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            help()
            sys.exit()
        elif opt in ("-t", "--type"):
            ty = arg
        elif opt in ("-d", "--directory"):
            directory = arg

    if ty == "" or directory == "":
        help()
        sys.exit(2)

    if ty == "chips":
        build_chips_repository(directory)
        build_chips_chip(directory)
    elif ty == "hal":
        build_hal(directory)
    elif ty == "update":
        update(directory)
    else:
        help()
        sys.exit(2)
