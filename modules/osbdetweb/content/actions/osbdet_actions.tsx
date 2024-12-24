'use server'

//import { exec } from "child_process";

const { spawn, spawnSync } = require('node:child_process');

export async function control(command: String, service_id: String) {
  // Logging the start/stop attempt
  if ( command == "start" || command == "stop" ) {
    console.log(command + "ing " + service_id + "...")
  }
  // Command execution
  const exec_result = spawnSync('/home/osbdet/bin/osbdet-control.sh', [command, service_id]);
  // Logging execution's results
  if ( command == "start" || command == "stop" ) {
    console.log(service_id + " " + command + "ed: status='" + 
                exec_result.status + "', output = '" + exec_result.stdout.toString().trim() +  "'")
  }
  // Results returned
  return { 'status': exec_result.status, 'output':  exec_result.stdout.toString().trim() }
}

export async function poweroff() {
  // Command execution
  console.log("User clicked the power off button")
  const exec_result = spawnSync('sudo', ['poweroff']);
  // Results returned
  return { 'status': exec_result.status, 'output':  exec_result.stdout.toString().trim() }
}