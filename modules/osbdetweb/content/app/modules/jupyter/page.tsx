"use client";

import { poweroff } from "@/actions/osbdet_actions";

import CurrentPath from '@/app/path'

export default function Jupyter() {

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
                        <CurrentPath current_path="Jupyter"/>
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
                                    <span className="relative text-xl lg:text-3xl text-center "> JupyterLab 4.4.9</span>
                                    <img className="mt-5" src="/images/jupyter_banner.png"/>
                                </span>
                            </h2>
                        </div>
                        <p className="pt-4 pb-4"><strong className="text-lg">How to start it up:</strong> You don&apos;t have to, it&apos;s automatically started when the environment is started up.</p>
                        <p className="pb-4"><strong className="text-lg">How to shut it down:</strong> You don&apos;t have to, it&apos;s automatically stopped when the environment is shut down.</p>
                        <p><strong className="text-lg">How to access: </strong></p>
                        <ul className="pb-4 ml-8 mt-2 list-disc">
                            <li><em><strong>Jupyter UI -</strong></em> accessible via <a href="http://localhost:28888/lab" className="underline" target="_blank">http://localhost:28888/lab</a>; use the <strong>osbdet123$</strong> password when prompted.</li>
                        </ul>
                        <p className="pb-4"><strong className="text-lg">Description: </strong>JupyterLab is the latest web-based interactive development environment for notebooks, code, and data. Its flexible interface allows users to configure and arrange workflows in data science, scientific computing, computational journalism, and machine learning. A modular design invites extensions to expand and enrich functionality.</p>
                        <p className="pb-4"><strong className="text-lg">Project website: </strong> <a href="https://jupyter.org/" className="underline" target="_blank">https://jupyter.org</a></p>
                        <p className="pb-4"><strong className="text-lg">Additional notes:</strong><br/>
                            Jupyter Notebook is a core component of the environment as, by using the embedded terminal, allows its operation; additionally to the environment operation, <em>Jupyter Notebook is used to write notebooks and applications implementing non-production class use cases</em>.</p>
                        <p className="pb-4 ">Try to be as much organized as possible by relaying on folders; all those files belonging to the same notebook, application, ... should be in the same folder to easily find them and to avoid messing things up.</p>
                    </div>
                </article>
            </div>
        </main>
    )
}