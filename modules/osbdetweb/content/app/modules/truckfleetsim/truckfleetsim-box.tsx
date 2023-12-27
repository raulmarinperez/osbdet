import Link from 'next/link'

export default function TruckFleetSimBox() {
    return (
        <div className="lg:w-1/3 sm:w-1/2 p-4">
        <Link href="/truckfleetsim">
          <div className="flex relative">
          <img alt="gallery" className="absolute inset-0 w-full h-full object-cover object-center" src="/images/truckfleetsim_box_bg.png"/>
          <div className="px-8 py-10 relative z-10 w-full border-4 border-gray-200 bg-white opacity-0 hover:opacity-90">
            <h2 className="tracking-widest text-sm title-font font-medium text-indigo-500 mb-1">Truck Fleet Simulator</h2>
            <h1 className="title-font text-lg font-medium text-gray-900 mb-3">Data Generator</h1>
            <p className="leading-relaxed">Create events related to trucks going over different routes in real-time.</p>
          </div>
          </div>
        </Link>
      </div>
    )
}