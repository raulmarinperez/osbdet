//import Image from 'next/image';

import OSBDETControl2 from "@/components/osbdet_control2";

export default function NiFi() {

  //let [isPending, startTransition] = useTransition()

    return (
        <main className="z-40 relative">               
            <div className=" container py-24  flex justify-between px-4 mx-auto  gap-x-2 ">
                <article className="w-full   px-4 rounded-lg    mx-auto format format-sm sm:format-base lg:format-lg format-blue dark:format-invert">
                    <div className="relative py-4 lg:py-16 pt-0 lg:pt-24">
                        <div className="max-w-8xl   mx-auto  ">        
                            <h2 className=" mb-0 lg:mb-6 font-sans text-lg lg:text-3xl text-center lg:text-left font-bold leading-none tracking-tight text-gray-900   md:mx-auto">
                                <span className="relative inline-block">
                                    <svg viewBox="0 0 52 24" fill="currentColor" className="absolute text-black -top-4 left-12 z-0 hidden w-32 -mt-8 -ml-20 text-blue-gray-100 lg:w-32 lg:-ml-28 lg:-mt-10 sm:block">
                                        <defs>
                                            <pattern id="70326c9b-4a0f-429b-9c76-792941e326d5" x="0" y="0" width=".135" height=".30">
                                                <circle cx="1" cy="1" r="1"></circle>
                                            </pattern>
                                        </defs>
                                        <rect fill="url(#70326c9b-4a0f-429b-9c76-792941e326d5)" width="52" height="52">
                                        </rect>
                                    </svg>
                                    {/*<span className="relative text-xl lg:text-3xl text-center "> NiFi &lt;{data}&gt; <button onClick={create}>Play</button></span>*/}
                                    <span className="relative text-xl lg:text-3xl text-center "><OSBDETControl2 service_name="NiFi" service_id="nifi"/></span>
                                    <img className="mt-5" src="/images/nifi_banner.png"/>
                                </span>
                            </h2>
                        </div>
                        {/*<form method="post" action={create}>
                            <label>Select your favorite brand:
                                <select name="selectedBrand" defaultValue="apple">
                                    <option value="apple">Apple</option>
                                    <option value="oppo">Oppo</option>
                                    <option value="samsung">Samsung</option>
                                </select>
                            </label>
                            <label>
                                Enter the Count: <input type="number"
                                                        name="count"
                                                        placeholder="Specify how many do you want" />
                            </label>
                            <hr />
                            <button type="reset">Reset</button>
                            <button type="submit">Submit</button>
                        </form>*/}
                        {/*<button onClick={() => startTransition(() => { create()})}>
                            Add Comment
                           </button>*/}
                        <p className="pt-4 "> Justo et est sit accusam labore et dolores sadipscing ut accusam. Ipsum vero at amet
                            kasd dolore, accusam et voluptua labore diam sea duo no dolore voluptua, clita diam accusam lorem dolor
                            dolor no dolor. Et accusam vero elitr ea invidunt sit. Justo eirmod eirmod et dolor stet, sed sanctus
                            lorem elitr ipsum. At et dolor diam et aliquyam. Lorem lorem duo vero diam eirmod dolor. Takimata
                            voluptua nonumy et nonumy diam est, et ut gubergren sed sanctus sed lorem kasd sed, nonumy aliquyam
                            gubergren elitr ipsum ipsum nonumy rebum et voluptua. Elitr ut clita no sit diam diam amet dolor, sed
                            ipsum diam amet et rebum duo lorem gubergren, rebum amet stet ipsum eirmod, justo accusam dolore ipsum
                            accusam invidunt, gubergren ipsum voluptua gubergren sanctus kasd. Et stet est sed diam no justo. Amet
                            rebum diam erat dolor amet aliquyam sea no. Sit ipsum vero ea stet, aliquyam lorem sea sed sit no,
                            sanctus sea et amet takimata voluptua, sea amet sadipscing dolor sed magna eos diam, sanctus duo labore
                            eirmod vero dolore aliquyam sadipscing, dolore kasd sed sed stet amet eirmod clita, diam dolore lorem
                            sit magna duo stet eirmod lorem, clita erat duo ut sit magna stet,.</p>
                    </div>
                </article>
            </div>
            </main>
    )
}