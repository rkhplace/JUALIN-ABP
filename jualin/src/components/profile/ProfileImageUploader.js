"use client"
import { useRef } from "react"

export default function ProfileImageUploader({ imageUrl, onSelect }) {
  const fileRef = useRef(null)

  const openFile = () => fileRef.current?.click()

  const onFileChange = e => {
    const file = e.target.files?.[0]
    if (!file) return
    const previewUrl = URL.createObjectURL(file)
    onSelect(file, previewUrl)
  }

  return (
    <div className="flex flex-col items-start gap-4">
      <button 
        onClick={openFile} 
        className="px-6 py-2 bg-[#E53935] hover:bg-[#D32F2F] text-white rounded-lg transition-colors text-sm font-medium"
      >
        Upload new photo
      </button>
      <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={onFileChange} />
    </div>
  )
}