"use client";

import { poweroff } from "@/actions/osbdet_actions";

import Link from 'next/link'
import CurrentPath from '@/app/path'
import JupyterBox from '@/app/modules/jupyter/jupyter-box'
import NiFiBox from '@/app/modules/nifi/nifi-box'
import HadoopBox from '@/app/modules/hadoop/hadoop-box'
import SparkBox from '@/app/modules/spark/spark-box'
import KafkaBox from '@/app/modules/kafka/kafka-box'
import TruckFleetSimBox from '@/app/modules/truckfleetsim/truckfleetsim-box'
import MariaDBBox from '@/app/modules/mariadb/mariadb-box'
import SuperSetBox from '@/app/modules/superset/superset-box'
import MongoDBBox from '@/app/modules/mongodb/mongodb-box'
import MinIOBox from '@/app/modules/minio/minio-box'
import KestraBox from '@/app/modules/kestra/kestra-box'
import GrafanaBox from '@/app/modules/grafana/grafana-box'
import OpenMetadataBox from '@/app/modules/openmetadata/openmetadata-box'

export default function Page() {

  function handleClick() {
    const stopOSBDET = async () => {
      const exec_result = await poweroff()
      if (exec_result.status == 0) {
        console.log("Environment stopped")
      }
      else {
        console.log("ERROR: unable to stop OSBDET - " + exec_result.output)
      }
      
    }
    stopOSBDET()
  }

  return (
    <section className="text-gray-600 body-font">
      {/* "Top bar" menu */}
      <div className="container px-5 py-5 mx-auto">
        <div className="grid grid-cols-2 gap-1">
          <div className="col-start-1 col-span-1">
            <CurrentPath current_path=""/>
          </div>
          <div className="col-start-2 col-span-1">
            <div className="flex flex-row-reverse mr-5">
            <button title="Switch the environment off" onClick={handleClick}>
              <img className="w-8 hover:drop-shadow-md" src="/images/poweroff.png"/>
            </button>
            </div>
          </div>
        </div>
      </div>
      {/* Intro text and buttons */}
      <div className="container px-5 pb-8 mx-auto">
        {/* Intro text */}
        <div className="flex flex-col text-left w-full mb-8">
          <h1 className="sm:text-3xl text-2xl font-medium title-font text-gray-900">
            OSBDET, <em>Open Source Big Data Educational Toolkit</em>, Home Page.</h1>
          <p className="sm mt-4 leading-relaxed text-base">
          Welcome to the <strong><em>OSBDET v2026r1</em></strong> homepage, your guide to exploring the environment&apos;s contents 
          and understanding how to use them effectively. Please note that this is an educational environment and is 
          <strong><em> not suitable for production use cases</em></strong>, as it is designed to run on a single node and 
          cannot scale to handle large data volumes. Use OSBDET to learn about the available frameworks or to validate concepts with 
          small datasets.</p>
          <p className="sm mt-4 leading-relaxed text-base">Tips to Keep the environment usable:</p>
          <ul className="ml-8 mt-2 list-disc">
            <li>Enable only the technologies you intend to use.</li>
            <li>Avoid attempting to run more than two technologies simultaneously, as this may cause issues.</li>
            <li>Shut down the environment after use to free up resources and improve your computer&apos;s performance.</li>
          </ul>
          <p className="sm mt-4 leading-relaxed text-base">
          For more information visit the <strong><em><Link className="underline" href="https://github.com/raulmarinperez/osbdet" target="_blank">OSBDET&apos;s Github repository</Link></em></strong>.</p>
          <h1 className="sm:text-2xl mt-4 text-2xl font-medium title-font text-gray-900">
            Available tools and frameworks:</h1>
        </div>
        {/* Buttons */}
        <div className="flex flex-wrap h-full w-full -m-4">
          <JupyterBox/>
          <NiFiBox/>
          <HadoopBox/>
          <SparkBox/>
          <KafkaBox/>
          <TruckFleetSimBox/>
          <MariaDBBox/>
          <SuperSetBox/>
          <MongoDBBox/>
          <MinIOBox/>
          <KestraBox/>
          <GrafanaBox/>
          <OpenMetadataBox/>
        </div>
      </div>
    </section>
  )
}