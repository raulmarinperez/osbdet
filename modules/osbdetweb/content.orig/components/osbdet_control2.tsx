"use client";

import { control } from "@/actions/osbdet_actions";
import { useState, useEffect } from 'react';

export default function OSBDETControl2({ service_name, service_id }) {

  const [running, setRunning] = useState(false); // true -> running (up), false -> not running (down)
  const [switching, setSwitching] = useState(false); // true -> changing state, false -> not changing state

  useEffect(() => {
        console.log("useEffect called")
        const syncUpUI = async () => {

          // If not switching state, check state of serve (running, not running)
          if (!switching) {
            const exec_result = await control("status", service_id)
            if (exec_result.status == 0) {
              setRunning( exec_result.output=="up" )
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
              // TBD - error control
            }
            else {
              console.log("Stopping '" + service_id + "'")
              const exec_result = await control("stop", service_id)
              if (exec_result.status == 0) {
                setSwitching(false)
                console.log("'" + service_id + "' stopped")
              }
              // TBD - error control
            }
          }
        }
        syncUpUI()
      }, [running]);

  function handleClick() {
    console.log("Current status: '" + running + "'")
    setSwitching(true) // prevent doing anything while starting or stopping
    if (running) {
      console.log("Button to stop (on state) clicked")
      setRunning(false)
    }
    else {
      console.log("Button to start (off state) clicked")
      setRunning(true)
    }
  }

  // Component rendering
  if (!switching) {
    return (
        <span>{service_name} &lt;status TBD&gt; 
        <button onClick={handleClick}>
          <img className="inline-block align-middle w-8" 
              src={running ? "/images/on-button.png" : "/images/off-button.png"}/></button>
        </span>
    )
  }
  else {
    return (
        <span>{service_name} &lt;status TBD&gt; 
        <img className="inline-block align-middle w-8" 
              src={running ? "/images/on-button.png" : "/images/off-button.png"}/>
        <img className="inline-block align-middle w-4" src="/images/loading.gif"/>
        </span>
    )

  }
}