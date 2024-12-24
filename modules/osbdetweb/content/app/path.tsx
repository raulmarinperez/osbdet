import Link from 'next/link'

export default function CurrentPath({ current_path } : { current_path: String }) {

    if ( current_path == "" ) {
        return (
            <p><em>Home</em></p>
        )
    }
    else {
        return (
            <p><em><Link href="/" className="font-medium text-blue-600 dark:text-blue-500 hover:underline">Home</Link> / {current_path}</em></p>
        )

    }
}