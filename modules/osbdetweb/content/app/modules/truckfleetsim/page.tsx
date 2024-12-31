"use client";

import { poweroff } from "@/actions/osbdet_actions";

import CurrentPath from '@/app/path'

export default function TruckFleetSim() {

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
                        <CurrentPath current_path="Truck Fleet Simulator"/>
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
                                    <span className="relative text-xl lg:text-3xl text-center "> Truck Fleet Simulator</span>
                                    <img className="mt-5" src="/images/truckfleet-sim_banner.png"/>
                                </span>
                            </h2>
                        </div>
                            <p className="pt-4 pb-4">
                                <strong className="text-lg">How to manually start it up: </strong>Type the <code className="bg-slate-300 p-1">sudo service truckfleet-sim start</code> command 
                                in a Jupyter Terminal window:
                            </p>
                            <img className="w-[600px] pb-4 drop-shadow-md" src="/images/truckfleet-sim_start.png"/>
	                        <p className="pb-4">
                                <strong className="text-lg">How to manually shut it down: </strong>Type the <code className="bg-slate-300 p-1">sudo service truckfleet-sim stop</code> command in a 
                                Jupyter Terminal window:</p>
                            <img className="w-[600px] pb-4 drop-shadow-md" src="/images/truckfleet-sim_stop.png"/>
	                        <p className="pb-4"><strong className="text-lg">How to access: </strong>There is no user interface for the Truck Fleet Simulator.</p>
	                        <p><strong className="text-lg">Description: </strong>Data generator creating events related to trucks going over different 
                              routes whose drivers break the rules from time to time. Very handy for learning how to code real-time 
                              processing jobs. The trucking data simulator allows you to do the following:</p>
                            <ul className="pb-4 ml-8 mt-2 list-disc">
                                <li>Generate streaming events for different sensors on a truck</li>
                                <li>Control the number of trucks/drivers on the road</li>
                                <li>Control the number of events generated by each truck</li>
                                <li>Use real trucking routes with real lat/long locations for the truck</li>
                                <li>Control the output of the event (csv, json)</li>
                                <li>Control what metadata goes into the event (schema metadata)</li>
                                <li>Control where the event is generated (in a file, as an event into Kafka)</li>
                            </ul>
                            <p className="pb-4"><strong className="text-lg">Project website: </strong> <a href="https://github.com/georgevetticaden/sam-trucking-data-utils" className="underline" target="_blank">https://github.com/georgevetticaden/sam-trucking-data-utils</a></p>
                            <p className="pb-4 "><strong className="text-lg">Additional notes:</strong><br/>
                              The environment has a very simple configuration adding new events to the <code className="bg-slate-300 p-1">/opt/truckfleet-sim/truck-sensor-data/all-streams.txt</code> file; 
                              once you&apos;re done with the simulator don&apos;t forget to stop it, otherwise you might run out of disk space due to the amount of 
                              events generated and stored in the aforementioned file.</p>
                    </div>
                </article>
            </div>
        </main>
    )
}