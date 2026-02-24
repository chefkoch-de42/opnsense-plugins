<?php
/*
 * Copyright (C) 2024 os-wancarp contributors
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Called by pkg post-install script to register os-wancarp in
 * system.firmware.plugins so OPNsense shows it as "installed"
 * instead of "misconfigured" on the firmware page.
 */

if (!file_exists('/conf/config.xml')) {
    exit(0);
}

require_once 'config.inc';
require_once 'util.inc';

global $config;

$current = isset($config['system']['firmware']['plugins'])
    ? $config['system']['firmware']['plugins']
    : '';

$plugins = array_filter(explode(',', $current));

if (!in_array('os-wancarp', $plugins)) {
    $plugins[] = 'os-wancarp';
    $config['system']['firmware']['plugins'] = implode(',', $plugins);
    write_config('os-wancarp registered in firmware.plugins');
    echo "os-wancarp registered in firmware.plugins\n";
} else {
    echo "os-wancarp already in firmware.plugins\n";
}

