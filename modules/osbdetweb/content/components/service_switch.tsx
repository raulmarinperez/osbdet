"use client";

import { control } from "@/actions/osbdet_actions";
import { useState, useEffect } from 'react';

export default function ServiceSwitch({ service_name, service_id } : { service_name: String, service_id: String }) {

  //console.log("Entering ServiceSwitch component")

  const [running, setRunning] = useState(false); // true -> running (up), false -> not running (down)
  const [switching, setSwitching] = useState(false); // true -> changing state, false -> not changing state

  useEffect(() => {
        //console.log("useEffect called within ServiceSwitch")
        const syncUpUI = async () => {

          // If not switching state, check state of service (running, not running)
          if (!switching) {
            const exec_result = await control("status", service_id)
            if (exec_result.status == 0) {
              setRunning( exec_result.output=="up" )
            }
            else {
              console.log("ERROR: unable to get the status of '" + service_id + "'  - " + exec_result.output)
            }
          }
          else {
            if (running) {
              console.log("Starting '" + service_id + "'")
              const exec_result = await control("start", service_id)
              if (exec_result.status == 0) {
                setSwitching(false)
                console.log("'" + service_id + "' started")
              }
              else {
                console.log("ERROR: '" + service_id + "' didn't start - " + exec_result.output)
              }
            }
            else {
              console.log("Stopping '" + service_id + "'")
              const exec_result = await control("stop", service_id)
              if (exec_result.status == 0) {
                setSwitching(false)
                console.log("'" + service_id + "' stopped")
              }
              else {
                console.log("ERROR: '" + service_id + "' didn't stop - " + exec_result.output)
              }
            }
          }
        }
        syncUpUI()
      }, [running]);

  function handleClick() {
    //console.log("Current status: '" + running + "'")
    setSwitching(true) // prevent doing anything while starting or stopping
    if (running) {
      //console.log("Button to stop (on state) clicked")
      setRunning(false)
    }
    else {
      //console.log("Button to start (off state) clicked")
      setRunning(true)
    }
  }

  // Component rendering
  if (!switching) {
    //console.log("Returning button")
    return (
        <div className="flex flex-row-reverse relative w-full">
          <button onClick={handleClick}>
            <img className="w-8" src={running ? "/images/on-button.png" : "/images/off-button.png"}/>
          </button>
        </div>
    )
  }
  else {
    //console.log("Returning image")
    return (
        <div className="flex flex-row-reverse relative w-full">
          <img className="w-8" src={running ? "/images/on-button.png" : "/images/off-button.png"}/>
          <img className="w-8" src="/images/loading.gif"/>
        </div>
    )

  }
}