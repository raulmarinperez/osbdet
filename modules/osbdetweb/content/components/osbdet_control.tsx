"use client";

import { useTransition } from "react";
import { control } from "@/actions/osbdet_actions";

export default function OSBDETControl({ service_name}) {

    const [isPending, startTransition] = useTransition()

    if (isPending) {
        return (<span>Loading...</span>)
    }

    return (
        <span><button onClick={(e) => {
            startTransition(() => {
                // change icon (animation) -> no needed
                control();
                // change icon based on results ()
              }) 
        }}>Oper</button></span>
    )
}