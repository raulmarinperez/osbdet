import Link from 'next/link'
import OSBDETServiceStatus from "@/components/osbdet_service_status";

export default function GrafanaBox() {
    return (
        <div className="lg:w-1/3 sm:w-1/2 p-4">
        <Link href="/grafana">
          <div className="flex relative">
          <img alt="gallery" className="absolute inset-0 w-full h-full object-cover object-center" src="/images/grafana_box_bg.png"/>
            <OSBDETServiceStatus service_id="grafana"/>
          <div className="px-8 py-10 relative z-10 w-full border-4 border-gray-200 bg-white opacity-0 hover:opacity-90">
            <h2 className="tracking-widest text-sm title-font font-medium text-indigo-500 mb-1">Grafana 9.3.2</h2>
            <h1 className="title-font text-lg font-medium text-gray-900 mb-3">Data Visualization</h1>
            <p className="leading-relaxed">Query, visualize, alert on, and understand your data no matter where it's stored.</p>
          </div>
          </div>
        </Link>
      </div>
    )
}