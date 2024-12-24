"use client";

import { poweroff } from "@/actions/osbdet_actions";

import CurrentPath from '@/app/path'

export default function Hadoop() {

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
                        <CurrentPath current_path="Hadoop"/>
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
                                    <span className="relative text-xl lg:text-3xl text-center ">Apache Hadoop 3.3.6</span>
                                    <img className="mt-5" src="/images/hadoop_banner.png"/>
                                </span>
                            </h2>
                        </div>
                        <p className="pt-4 pb-4">
                            <strong className="text-lg">How to manually start it up: </strong>Type the <code className="bg-slate-300 p-1">sudo service hadoop3 start</code> command in a Jupyter Terminal window:
                        </p>
                        <img className="w-[600px] pb-4 drop-shadow-md" src="/images/hadoop_start.png"/>
                        <p className="pb-4">
                            <strong className="text-lg">How to manually shut it down: </strong>Type the <code className="bg-slate-300 p-1">sudo service hadoop3 stop</code> command in a Jupyter Terminal window:
                        </p>
                        <img className="w-[600px] pb-4 drop-shadow-md" src="/images/hadoop_stop.png"/>
                        <p><strong className="text-lg">How to access: </strong>There are several resources you can access to:</p>
                        <ul className="pb-4 ml-8 mt-2 list-disc">
                            <li><em><strong>HDFS Web UI -</strong></em> accessible via <a href="http://localhost:50070" className="underline" target="_blank">http://localhost:50070</a></li>
                            <li><em><strong>YARN Web UI -</strong></em> accessible via <a href="http://localhost:28088" className="underline" target="_blank">http://localhost:28088</a></li>
                        </ul>
                        <p className="pb-4"><strong className="text-lg">Description:</strong> The Apache Hadoop software library is a framework that allows for the 
                            distributed processing of large data sets across clusters of computers using simple programming 
                            models. It is designed to scale up from single servers to thousands of machines, each offering local 
                            computation and storage. Rather than rely on hardware to deliver high-availability, the library itself 
                            is designed to detect and handle failures at the application layer, so delivering a highly-available 
                            service on top of a cluster of computers, each of which may be prone to failures.
                        </p>
                        <p className="pb-4">
                            <strong className="text-lg">Project website: </strong> <a href="https://hadoop.apache.org/" className="underline" target="_blank">https://hadoop.apache.org/</a>
                        </p>
                        <p className="pb-4 "><strong className="text-lg">Additional notes:</strong><br/>
                            Hadoop is available in the environment mainly for storage purposes (HDFS), although it can be used to 
                            see the MapReduce processing paradigm in action.<br/><em>Don&apos;t forget to shut it down</em> if you&apos;re 
                            no longer using it, it&apos;ll save some CPU and memory resources for other tasks you might want to work on.
                        </p>
                    </div>
                </article>
            </div>
        </main>
    )
}