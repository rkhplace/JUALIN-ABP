export const formatDate = (dateString) => {
  const date = new Date(dateString);
  return date.toLocaleDateString('id-ID', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
};

export const formatTime = (dateString) => {
  const date = new Date(dateString);
  return date.toLocaleTimeString('id-ID', {
    hour: '2-digit',
    minute: '2-digit'
  });
};

export const formatDateTime = (dateString) => {
  const date = new Date(dateString);
  return date.toLocaleString('id-ID');
};

export const splitDateTime = (dateString) => {
  const formatted = formatDateTime(dateString);
  const [date, time] = formatted.split(', ');
  return { date, time };
};

export const formatOfferedAgo = (dateString) => {
  if (!dateString) return '';

  const createdAt = new Date(dateString);
  const createdTime = createdAt.getTime();
  if (Number.isNaN(createdTime)) return '';

  const diffMs = Math.max(Date.now() - createdTime, 0);
  const minutes = Math.floor(diffMs / 60000);

  if (minutes < 1) return 'Ditawarkan baru saja';
  if (minutes < 60) return `Ditawarkan ${minutes} menit yang lalu`;

  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `Ditawarkan ${hours} jam yang lalu`;

  const days = Math.floor(hours / 24);
  if (days < 30) return `Ditawarkan ${days} hari yang lalu`;

  const months = Math.floor(days / 30);
  if (months < 12) return `Ditawarkan ${months} bulan yang lalu`;

  const years = Math.floor(days / 365);
  return `Ditawarkan ${years} tahun yang lalu`;
};
