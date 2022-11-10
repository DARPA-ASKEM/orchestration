module.exports = (title, payload, url) => {
	const header = `## ${title} :rotating_light:\n\n`;
	const preface = 'In order to merge this pull request, the following need to be resolved.\n\n';
	// NOTE: these need to be far left otherwise the formatting output fails due to tab
	const errors = `#### Issues:
\`\`\`
${payload}
\`\`\`
`;

	if (url) {
		const separator = '---\n\n';
		const footer = url ? `:books: For more information, visit ${url}.` : '';
		return header + preface + errors + separator + footer;
	}

	return header + preface + errors;
}
