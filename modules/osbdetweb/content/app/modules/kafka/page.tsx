"use client";

import { poweroff } from "@/actions/osbdet_actions";

import CurrentPath from '@/app/path'

export default function Kafka() {

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
        <main className="z-40 relative">  
            <div className="container px-5 py-5 mx-auto">
                <div className="grid grid-cols-2 gap-1">
                    <div className="col-start-1 col-span-1">
                        <CurrentPath current_path="Kafka"/>
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
            <div className=" container flex justify-between px-4 mx-auto gap-x-2 ">
                <article className="w-full px-4 rounded-lg mx-auto format format-sm sm:format-base lg:format-lg format-blue dark:format-invert">
                    <div className="relative pt-0">
                        <div className="max-w-8xl mx-auto">        
                            <h2 className=" mb-0 lg:mb-6 font-sans text-lg lg:text-3xl text-center lg:text-left font-bold leading-none tracking-tight text-gray-900   md:mx-auto">
                                <span className="relative inline-block">
                                    <span className="relative text-xl lg:text-3xl text-center ">Apache Kafka 4.1.1</span>
                                    <img className="mt-5" src="/images/kafka_banner.png"/>
                                </span>
                            </h2>
                        </div>
                        <p className="pt-4 pb-4">
                            <strong className="text-lg">How to manually start it up: </strong>Type the <code className="bg-slate-300 p-1">sudo service kafka start</code> command in a 
                            Jupyter Terminal window:
                        </p>
                        <img className="w-[600px] pb-4 drop-shadow-md" src="/images/kafka_start.png"/>
                        <p className="pb-4">
                            <strong className="text-lg">How to manually shut it down: </strong>Type the <code className="bg-slate-300 p-1">sudo service kafka stop</code> command in a 
                            Jupyter Terminal window:
                        </p>
                        <img className="w-[600px] pb-4 drop-shadow-md" src="/images/kafka_stop.png"/>
                        <p className="pb-4"><strong className="text-lg">How to access: </strong>There is no user interface for Kafka.</p>
                        <p className="pb-4"><strong className="text-lg">Description: </strong>Apache Kafka is an open-source distributed event streaming platform 
                            used by thousands of companies for high-performance data pipelines, streaming analytics, data 
                            integration, and mission-critical applications.</p>
                        <p className="pb-4"><strong className="text-lg">Project website: </strong> <a href="https://kafka.apache.org/" className="underline" target="_blank">https://kafka.apache.org/</a></p>
                        <p className="pb-4 "><strong className="text-lg">Additional notes:</strong><br/>
                            The Kafka deployment in this environment doesn&apos;t rely on Zookeeper but on a variation of the Raft 
                            consensus procol called <a href="https://developer.confluent.io/learn/kraft/" target="_blank">KRaft</a>.</p>
                    </div>
                </article>
            </div>
        </main>
    )
}