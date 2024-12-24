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
import AirflowBox from '@/app/modules/airflow/airflow-box'
import GrafanaBox from '@/app/modules/grafana/grafana-box'

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
          Welcome to the <strong><em>OSBDET v2024r1</em></strong> home page which will drive you through all the contents in the 
          environment and how to make them work. Please, bear in mind this is an educational environment and <strong><em>it shouldn&apos;t 
          be used for production use cases</em></strong> as it doesn&apos;t scale to handle large volumes of data (everything runs on one single 
          node); use it to learn the different frameworks available in the environment or to proof concepts with small datasets.</p>
          <p className="sm mt-4 leading-relaxed text-base">A few tips to avoid making the environment unusable:</p>
          <ul className="ml-8 mt-2 list-disc">
            <li>Only enable the technology that you are going to use.</li>
            <li>Most likely, you won&apos;t be able to make more than two technologies work together.</li>
            <li>Shut down the environment once you&apos;re done, that&apos;ll release resources and will make your computer work better.</li>
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
          <AirflowBox/>
          <GrafanaBox/>
        </div>
      </div>
    </section>
  )
}