import Link from 'next/link'
import ServiceSwitch from "@/components/service_switch";

export default function HadoopBox() {
  return (
    <div className="lg:w-1/3 sm:w-1/2 p-4">
      <div className="flex flex-col relative">
        {/* Box image */}
        <img alt="gallery" className="absolute inset-0 w-full object-cover object-center drop-shadow-md" 
             src="/images/hadoop_box_bg.png"/>
        {/* row containing switch and links - implemented as a one column grid */}
        <div className="grid grid-cols-3 gap-2 relative w-full z-10">
          <div className="col-span-2">
            <div className="flex flex-row relative pt-2 pb-2 h-full w-full">
              <span className="ml-2">
                <Link href="/modules/hadoop" title="More info about the module"><img className="w-[24px] hover:drop-shadow-md" src="/images/info.png"/></Link>
              </span>
              <span className="ml-2">
                <Link href="http://localhost:50070" title="Open the HDFS UI" target="_blank"><img className="w-[24px] hover:drop-shadow-md" src="/images/ui.png"/></Link>
              </span>
              <span className="ml-2">
                <Link href="http://localhost:28088" title="Open the YARN UI" target="_blank"><img className="w-[24px] hover:drop-shadow-md" src="/images/ui.png"/></Link>
              </span>
            </div>
          </div>
          <div className="col-span-1">
            <div className="flex flex-row-reverse relative w-full">
              <div className="w-16 mr-2">
                <ServiceSwitch service_name="Hadoop" service_id="hadoop3"/>
              </div>
            </div>
          </div>
        </div>
        {/* Text box with information */}
        <div className="container w-full px-8 py-1 h-full opacity-0 hover:opacity-90">
          <div className="flex flex-col w-full border-4 p-4 border-gray-200 bg-white ">
              <h2 className="tracking-widest text-sm title-font font-medium text-indigo-500 mb-1">Hadoop 3.3.6</h2>
              <h1 className="title-font text-lg font-medium text-gray-900 mb-3">Data Storage and Processing</h1>
              <p className="leading-relaxed">Distributed processing of large data sets across clusters of computers.</p>
          </div>
        </div>
      </div>
    </div>
  )
}