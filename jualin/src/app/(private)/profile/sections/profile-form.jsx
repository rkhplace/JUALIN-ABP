"use client";

/**
 * ProfileFormSection
 * Edit profile form with photo upload, personal info, location, and bio
 * Used in profile/edit/page.jsx
 */
export function ProfileFormSection({
  form,
  errors,
  imagePreview,
  onFieldChange,
  onImageSelect,
}) {
  return (
    <>
      

      {/* Profile Photo and Upload */}
      <div className="bg-white rounded-xl p-4 sm:p-6 md:p-8 mb-6 md:mb-8 shadow-md hover:shadow-lg transition-all duration-200">
        <div className="flex items-center gap-4 sm:gap-8">
          <div className="w-20 h-20 sm:w-24 sm:h-24 md:w-28 md:h-28 shrink-0 rounded-full overflow-hidden border-2 border-gray-200">
            {imagePreview ? (
              <img
                src={imagePreview}
                alt="Profile"
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center bg-gray-100 text-gray-400">
                <svg
                  className="w-10 h-10 md:w-12 md:h-12"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fillRule="evenodd"
                    d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z"
                    clipRule="evenodd"
                  />
                </svg>
              </div>
            )}
          </div>
          <div className="flex-1 min-w-0">
            <button
              onClick={() => document.getElementById("profilePicture").click()}
              className="px-4 py-2 sm:px-6 bg-white hover:bg-white text-[#1F1F1F] rounded-lg transition-all duration-200 text-xs sm:text-sm font-medium shadow-md hover:shadow-lg focus:shadow-xl outline-none"
            >
              Unggah Foto Baru
            </button>
            <p className="text-[11px] sm:text-xs text-[#9CA3AF] mt-2 leading-snug">
              Disarankan minimal 800×800 px. JPG atau PNG diperbolehkan
            </p>
            <input
              id="profilePicture"
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) {
                  onImageSelect(file);
                }
              }}
            />
          </div>
        </div>
      </div>
      {/* Error Message for Image Upload */}
      {errors.profile_picture && (
        <div className="mb-6 p-3 sm:p-4 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
          {errors.profile_picture}
        </div>
      )}

      {/* Personal Info Card */}
      <div className="bg-white rounded-xl p-4 sm:p-6 md:p-8 mb-6 md:mb-8 shadow-md hover:shadow-lg transition-all duration-200">
        <div className="flex items-center justify-between mb-5 md:mb-6">
          <h2 className="text-lg font-semibold text-[#1F1F1F]">
            Informasi Pribadi
          </h2>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6 mb-4 md:mb-6">
          <div>
            <label className="block text-sm font-medium text-[#9CA3AF] mb-2">
              Nama Lengkap
            </label>
            <input
              type="text"
              value={form.username}
              onChange={(e) => onFieldChange("username", e.target.value)}
              className={`w-full px-4 py-2.5 md:py-3 rounded-lg outline-none transition-all duration-200 bg-white text-black shadow-md hover:shadow-lg focus:shadow-xl ${
                errors.username ? "shadow-red-300 focus:shadow-red-400" : ""
              }`}
              placeholder="Nama Anda"
            />
            {errors.username && (
              <p className="mt-1 text-sm text-red-600">{errors.username}</p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-[#9CA3AF] mb-2">
              Email
            </label>
            <input
              type="email"
              value={form.email}
              onChange={(e) => onFieldChange("email", e.target.value)}
              className={`w-full px-4 py-2.5 md:py-3 rounded-lg outline-none transition-all duration-200 bg-white text-black shadow-md hover:shadow-lg focus:shadow-xl ${
                errors.email ? "shadow-red-300 focus:shadow-red-400" : ""
              }`}
              placeholder="name@example.com"
            />
            {errors.email && (
              <p className="mt-1 text-sm text-red-600">{errors.email}</p>
            )}
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6">
          <div>
            <label className="block text-sm font-medium text-[#9CA3AF] mb-2">
              Nomor Telepon
            </label>
            <input
              type="tel"
              value={form.phone}
              onChange={(e) => onFieldChange("phone", e.target.value)}
              className={`w-full px-4 py-2.5 md:py-3 rounded-lg outline-none transition-all duration-200 bg-white text-black shadow-md hover:shadow-lg focus:shadow-xl ${
                errors.phone ? "shadow-red-300 focus:shadow-red-400" : ""
              }`}
              placeholder="Contoh: 081234567890"
              maxLength={20}
            />
            {errors.phone && (
              <p className="mt-1 text-sm text-red-600">{errors.phone}</p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-[#9CA3AF] mb-2">
              Gender
            </label>
            <select
              value={form.gender}
              onChange={(e) => onFieldChange("gender", e.target.value)}
              className="w-full px-4 py-2.5 md:py-3 rounded-lg outline-none transition-all duration-200 bg-white text-black shadow-md hover:shadow-lg focus:shadow-xl"
            >
              <option value="male">Male</option>
              <option value="female">Female</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-[#9CA3AF] mb-2">
              Birthday
            </label>
            <input
              type="date"
              value={form.birthday}
              onChange={(e) => onFieldChange("birthday", e.target.value)}
              className="w-full px-4 py-2.5 md:py-3 rounded-lg outline-none transition-all duration-200 bg-white text-black shadow-md hover:shadow-lg focus:shadow-xl"
            />
          </div>
        </div>
      </div>

      {/* Location Card */}
      <div className="bg-white rounded-xl p-4 sm:p-6 md:p-8 mb-6 md:mb-8 shadow-md hover:shadow-lg transition-all duration-200">
        <div className="flex items-center justify-between mb-5 md:mb-6">
          <h2 className="text-lg font-semibold text-[#1F1F1F]">Lokasi</h2>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6">
          <div>
            <label className="block text-sm font-medium text-[#9CA3AF] mb-2">
              Lokasi
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <svg
                  className="h-5 w-5 text-[#9CA3AF]"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fillRule="evenodd"
                    d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z"
                    clipRule="evenodd"
                  />
                </svg>
              </div>
              <input
                type="text"
                value={form.region}
                onChange={(e) => onFieldChange("region", e.target.value)}
                className={`w-full pl-10 pr-4 py-2.5 md:py-3 rounded-lg outline-none transition-all duration-200 bg-white text-black shadow-md hover:shadow-lg focus:shadow-xl ${
                  errors.region ? "shadow-red-300 focus:shadow-red-400" : ""
                }`}
                placeholder="Provinsi Anda"
              />
            </div>
            {errors.region && (
              <p className="mt-1 text-sm text-red-600">{errors.region}</p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-[#9CA3AF] mb-2">
              Kota
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <svg
                  className="h-5 w-5 text-[#9CA3AF]"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fillRule="evenodd"
                    d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z"
                    clipRule="evenodd"
                  />
                </svg>
              </div>
              <input
                type="text"
                value={form.city}
                onChange={(e) => onFieldChange("city", e.target.value)}
                className={`w-full pl-10 pr-4 py-2.5 md:py-3 rounded-lg outline-none transition-all duration-200 bg-white text-black shadow-md hover:shadow-lg focus:shadow-xl ${
                  errors.city ? "shadow-red-300 focus:shadow-red-400" : ""
                }`}
                placeholder="Kota Anda"
              />
            </div>
            {errors.city && (
              <p className="mt-1 text-sm text-red-600">{errors.city}</p>
            )}
          </div>
        </div>
      </div>

      {/* Bio Card */}
      <div className="bg-white rounded-xl p-4 sm:p-6 md:p-8 mb-6 md:mb-8 shadow-md hover:shadow-lg transition-all duration-200">
        <div className="flex items-center justify-between mb-5 md:mb-6">
          <h2 className="text-lg font-semibold text-[#1F1F1F]">Bio</h2>
        </div>
        <div>
          <textarea
            value={form.bio}
            onChange={(e) => onFieldChange("bio", e.target.value)}
            rows={5}
            className={`w-full px-4 py-2.5 md:py-3 rounded-lg outline-none transition-all duration-200 bg-white text-black shadow-md hover:shadow-lg focus:shadow-xl resize-none ${
              errors.bio ? "shadow-red-300 focus:shadow-red-400" : ""
            }`}
            placeholder="Ceritakan tentang diri Anda"
          />
          {errors.bio && (
            <p className="mt-1 text-sm text-red-600">{errors.bio}</p>
          )}
          <p className="mt-2 text-sm text-[#9CA3AF]">
            {form.bio.length}/500 karakter
          </p>
        </div>
      </div>
    </>
  );
}
