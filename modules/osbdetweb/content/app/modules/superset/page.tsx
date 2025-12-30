"use client";

import { poweroff } from "@/actions/osbdet_actions";

import CurrentPath from '@/app/path'

export default function Superset() {

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
                        <CurrentPath current_path="Superset"/>
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
                                    <span className="relative text-xl lg:text-3xl text-center ">Apache Superset 5.0.0</span>
                                    <img className="mt-5" src="/images/superset_banner.png"/>
                                </span>
                            </h2>
                        </div>
                        <p className="pt-4 pb-4"><strong className="text-lg">How to manually start it up: </strong>Type the <code className="bg-slate-300 p-1">sudo service superset start</code> command in a Jupyter Terminal window:</p>
                        <img className="w-[600px] pb-4 drop-shadow-md" src="/images/superset_start.png"/> 
	                    <p className="pb-4"><strong className="text-lg">How to manually shut it down: </strong>Type the <code className="bg-slate-300 p-1">sudo service superset stop</code> command in a Jupyter Terminal window:</p>
                        <img className="w-[600px] pb-4 drop-shadow-md" src="/images/superset_stop.png"/> 
	                    <p><strong className="text-lg">How to access: </strong></p>
                        <ul className="ml-8 mt-2 list-disc">
                            <li>
                                <em><strong>Superset Web UI -</strong></em> accessible via <a href="http://localhost:28880" className="underline" target="_blank">http://localhost:28880</a>; log into Superset as user <em><strong>osbdet</strong></em> with password <em><strong>osbdet123$</strong></em>.                                    
                                <img className="w-[600px] drop-shadow-md pt-4 pb-4" src="/images/superset_login.png"/>
                            </li>   
                        </ul>	                    
	                    <p className="pb-4"><strong className="text-lg">Description: </strong>Superset is fast, lightweight, intuitive, and loaded with options that make 
                          it easy for users of all skill sets to explore and visualize their data, from simple line charts to highly 
                          detailed geospatial charts.</p>
                        <p className="pb-4"><strong className="text-lg">Project website: </strong> <a href="https://superset.apache.org" className="underline" target="_blank">https://superset.apache.org</a></p>
                        <p className="pb-4 "><strong className="text-lg">Additional notes:</strong><br/>
                          MySQL client libraries (MariaDB compatible) allowing the access to the MariaDB instance are available in 
                          the course environment.</p>
                    </div>
                </article>
            </div>
        </main>
    )
}