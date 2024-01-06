const { spawnSync } = require('node:child_process');

export default function OSBDETService({ service_name}) {

    const echo = spawnSync('echo', ['jeje']);

    return (
        <span>{service_name} &lt;{echo.output.toString('utf8')}&gt;</span>
    )
}