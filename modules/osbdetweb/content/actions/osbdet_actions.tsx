'use server'

import { exec } from "child_process";

const { spawn, spawnSync } = require('node:child_process');

export async function control(command: String, service_id: String) {
  console.log("running " + command + " on " + service_id)
  const exec_result = spawnSync('/home/osbdet/bin/osbdet-control.sh', [command, service_id]);

  return { 'status': exec_result.status, 'output':  exec_result.stdout.toString().trim() }
}

export async function status() {
    'use server'
    const echo = spawnSync('echo', ['jeje']);

    return echo.output
  }