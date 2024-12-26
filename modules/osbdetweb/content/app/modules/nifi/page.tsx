"use client";

import { poweroff } from "@/actions/osbdet_actions";

import CurrentPath from '@/app/path'

export default function NiFi() {

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
                    <CurrentPath current_path="NiFi"/>
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
                            <h2 className=" mb-0 lg:mb-6 font-sans text-lg lg:text-3xl text-center lg:text-left font-bold leading-none tracking-tight text-gray-900 md:mx-auto">
                                <span className="relative inline-block">
                                    <span className="relative text-xl lg:text-3xl text-center ">Apache NiFi 2.0.0</span>
                                    <img className="mt-5" src="/images/nifi_banner.png"/>
                                </span>
                            </h2>
                        </div>
                        <p className="pt-4 pb-4">
                            <strong className="text-lg">How to manually start it up: </strong>Type the <code className="bg-slate-300 p-1">nifi.sh start</code> command in a Jupyter Terminal window:
                        </p>
                        <img className="w-[600px] pb-4 drop-shadow-md" src="/images/nifi_start.png"/>
	                    <p className="pb-4">
                            <strong className="text-lg">How to manually shut it down: </strong>Type the <code className="bg-slate-300 p-1">nifi.sh stop</code> command in a Jupyter Terminal window:
                        </p>
                        <img className="w-[600px] pb-4 drop-shadow-md" src="/images/nifi_stop.png"/>
                        <p><strong className="text-lg">How to access: </strong></p>
                        <ul className="pb-4 ml-8 mt-2 list-disc">
                            <li><em><strong>NiFi Web UI -</strong></em> accessible via <a href="http://localhost:29090/nifi" className="underline" target="_blank">http://localhost:29090/nifi</a></li>   
                        </ul>
	                    <p className="pb-4"><strong className="text-lg">Description: </strong>Put simply, NiFi was built to automate the flow of data between systems. 
                          While the term &apos;dataflow&apos; is used in a variety of contexts, we use it here to mean the automated and 
                          managed flow of information between systems. This problem space has been around ever since enterprises 
                          had more than one system, where some of the systems created data and some of the systems consumed data. 
                          The problems and solution patterns that emerged have been discussed and articulated extensively.</p>
                        <p className="pb-4"><strong className="text-lg">Project website: </strong> <a href="https://nifi.apache.org/" className="underline" target="_blank">https://nifi.apache.org/</a></p>
                        <p className="pb-4 "><strong className="text-lg">Additional notes:</strong><br/>
                          Before you stop NiFi <strong>be sure that all the data flows are stopped</strong>, otherwise the next 
                          time you start NiFi those non-stopped data flows will start up automatically and that might cause some 
                          impredictable consequences (ex. run out of disk space, slow the whole environment down, ...) .<br/>Once 
                          you&apos;re done with NiFi, <em>don&apos;t forget to stop it</em> to release resources and use them for other tasks.
                        </p>
                    </div>
                </article>
            </div>
            </main>
    )
}
