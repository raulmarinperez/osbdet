import Link from 'next/link'

export default function SparkBox() {
    return (
        <div className="lg:w-1/3 sm:w-1/2 p-4">
        <Link href="/spark">
          <div className="flex relative">
          <img alt="gallery" className="absolute inset-0 w-full h-full object-cover object-center" src="/images/spark_box_bg.png"/>
          <img className="absolute w-4 top-2 right-2" src="/images/green_dot_32px.png"/>
          <div className="px-8 py-10 relative z-10 w-full border-4 border-gray-200 bg-white opacity-0 hover:opacity-90">
            <h2 className="tracking-widest text-sm title-font font-medium text-indigo-500 mb-1">Spark 3.2.3</h2>
            <h1 className="title-font text-lg font-medium text-gray-900 mb-3">Data Processing</h1>
            <p className="leading-relaxed">Multi-language and unified processing engine running on one or many machines.</p>
          </div>
          </div>
        </Link>
      </div>
    )
}