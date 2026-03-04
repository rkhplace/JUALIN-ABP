"use client"
export default function ProfileForm({ value, errors = {}, onChange }) {
  return (
    <div className="space-y-6">
      <section>
        <h2 className="text-sm font-medium text-gray-700 mb-3">Personal Info</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-xs text-gray-500 mb-1">Full Name</label>
            <input value={value.fullName} onChange={e => onChange("fullName", e.target.value)} className={`w-full rounded-md border px-3 py-2 ${errors.fullName ? "border-red-500" : ""}`} placeholder="Your name" />
            {errors.fullName && <p className="mt-1 text-xs text-red-600">{errors.fullName}</p>}
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-1">Email</label>
            <input type="email" value={value.email} onChange={e => onChange("email", e.target.value)} className={`w-full rounded-md border px-3 py-2 ${errors.email ? "border-red-500" : ""}`} placeholder="name@example.com" />
            {errors.email && <p className="mt-1 text-xs text-red-600">{errors.email}</p>}
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-1">Phone</label>
            <input value={value.phone} onChange={e => onChange("phone", e.target.value)} className={`w-full rounded-md border px-3 py-2 ${errors.phone ? "border-red-500" : ""}`} placeholder="(+62) 8123456789" />
            {errors.phone && <p className="mt-1 text-xs text-red-600">{errors.phone}</p>}
          </div>
        </div>
      </section>

      <section>
        <h2 className="text-sm font-medium text-gray-700 mb-3">Location</h2>
        <div>
          <div className={`flex items-center gap-2 rounded-md border px-3 py-2 ${errors.location ? "border-red-500" : ""}`}>
            <span className="text-gray-400">📍</span>
            <input value={value.location} onChange={e => onChange("location", e.target.value)} className="flex-1 outline-none" placeholder="Your location" />
          </div>
          {errors.location && <p className="mt-1 text-xs text-red-600">{errors.location}</p>}
        </div>
      </section>

      <section>
        <h2 className="text-sm font-medium text-gray-700 mb-3">Bio</h2>
        <textarea value={value.bio} onChange={e => onChange("bio", e.target.value)} rows={6} className={`w-full rounded-md border px-3 py-2 ${errors.bio ? "border-red-500" : ""}`} placeholder="Tell us about yourself" />
        {errors.bio && <p className="mt-1 text-xs text-red-600">{errors.bio}</p>}
      </section>
    </div>
  )
}