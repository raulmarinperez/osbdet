import JupyterBox from '@/app/modules/jupyter/jupyter-box'
import NiFiBox from '@/app/modules/nifi/nifi-box'
import HadoopBox from '@/app/modules/hadoop/hadoop-box'
import SparkBox from '@/app/modules/spark/spark-box'
import KafkaBox from '@/app/modules/kafka/kafka-box'
import TruckFleetSimBox from '@/app/modules/truckfleetsim/truckfleetsim-box'
import MariaDBBox from '@/app/modules/mariadb/mariadb-box'
import SuperSetBox from '@/app/modules/superset/superset-box'
import MongoDBBox from '@/app/modules/mongodb/mongodb-box'
import MinIOBox from '@/app/modules/minio/minio-box'
import AirflowBox from '@/app/modules/airflow/airflow-box'
import GrafanaBox from '@/app/modules/grafana/grafana-box'

export default function Page() {
    return (
<section className="text-gray-600 body-font">
  <div className="container px-5 py-24 mx-auto">
    <div className="flex flex-col text-left w-full mb-8">
      <h1 className="sm:text-3xl text-2xl font-medium title-font text-gray-900">
        OSBDET, <em>Open Source Big Data Educational Toolkit</em>, Home Page.</h1>
      <p className="sm mt-4 leading-relaxed text-base">
      Welcome to the <strong><em>OSBDET v2024r1</em></strong> home page which will drive you through all the contents in the 
      environment and how to make it work. Please, bear in mind this is an educational environment and <strong><em>it shouldn't 
      be used for production use cases</em></strong> as it doesn't scale to handle large volume of data (all runs in one single 
      node); use it to learn the different frameworks available in the environment or to proof concepts with small datasets.</p>
      <p className="sm mt-4 leading-relaxed text-base">
      For more information visit the <strong><em><a href="https://github.com/raulmarinperez/osbdet" target="_blank">OSBDET's Github repository</a></em></strong>.</p>
      <h1 className="sm:text-2xl mt-4 text-2xl font-medium title-font text-gray-900">
        Available tools and frameworks:</h1>
    </div>
    <div className="flex flex-wrap -m-4">
      <JupyterBox/>
      <NiFiBox/>
      <HadoopBox/>
      <SparkBox/>
      <KafkaBox/>
      <TruckFleetSimBox/>
      <MariaDBBox/>
      <SuperSetBox/>
      <MongoDBBox/>
      <MinIOBox/>
      <AirflowBox/>
      <GrafanaBox/>
    </div>
  </div>
</section>
     )
}