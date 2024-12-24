"use client";

import { control } from "@/actions/osbdet_actions";
import { useState, useEffect } from 'react';

export default function OSBDETServiceStatus({ service_id }) {

  const [running, setRunning] = useState(false); // true -> running (up), false -> not running (down)

  useEffect(() => {
        console.log("useEffect called")
        const syncUpUI = async () => {

          const exec_result = await control("status", service_id)
          if (exec_result.status == 0) {
            setRunning( exec_result.output=="up" )
          }
        }
        syncUpUI()
      }, [running]);

  // Component rendering
  return (
    <img className="absolute w-4 top-2 right-2" src={running ? "/images/green_dot_32px.png" : "/images/red_dot_32px.png"}/>
  )
}