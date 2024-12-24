import Link from 'next/link'
import OSBDETServiceStatus from "@/components/osbdet_service_status";

export default function AirflowBox() {
    return (
        <div className="lg:w-1/3 sm:w-1/2 p-4">
        <Link href="/airflow">
          <div className="flex relative">
          <img alt="gallery" className="absolute inset-0 w-full h-full object-cover object-center" src="/images/airflow_box_bg.png"/>
            <OSBDETServiceStatus service_id="airflow"/>
          <div className="px-8 py-10 relative z-10 w-full border-4 border-gray-200 bg-white opacity-0 hover:opacity-90">
            <h2 className="tracking-widest text-sm title-font font-medium text-indigo-500 mb-1">Airflow 2.5.0</h2>
            <h1 className="title-font text-lg font-medium text-gray-900 mb-3">Workflow Scheduler</h1>
            <p className="leading-relaxed">Platform to programmatically author, schedule and monitor workflows.</p>
          </div>
          </div>
        </Link>
      </div>
    )
}