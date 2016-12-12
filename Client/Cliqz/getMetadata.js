
function sendMetaData() {
	var title = window.document.querySelector("title"),
	description = window.document.querySelector("meta[name=description]"),
	ogTitle = window.document.querySelector("meta[property='og:title']"),
	ogDescription = window.document.querySelector("meta[property='og:description']"),
	ogImage = window.document.querySelector("meta[property='og:image']"),
	canonical = window.document.querySelector("link[rel='canonical']"),
	
	
	title = title && title.innerText && title.innerText.trim();
	description = description && description.content && description.content.trim();
	ogTitle = ogTitle && ogTitle.content && ogTitle.content.trim();
	ogDescription = ogDescription && ogDescription.content && ogDescription.content.trim();
	ogImage = ogImage && ogImage.content && ogImage.content.trim();
	canonical = canonical && canonical.href && canonical.href.trim();
	
	title = title || ogTitle || '';
	description = description || ogDescription || '';
	ogImage = ogImage || '';
	canonical = canonical || '';
	
	var metaData = {
	title: title,
	description: description,
	ogImage: ogImage,
	canonical: canonical,
	}
	
	return metaData;
}
