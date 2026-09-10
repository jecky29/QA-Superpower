FROM node:22-bookworm
WORKDIR /app
COPY package*.json ./
RUN npm install && npx playwright install --with-deps chromium
COPY . .
ENV HOST=0.0.0.0 PORT=7070 QA_DATA_DIR=/app/data QA_ARTIFACT_DIR=/app/artifacts
EXPOSE 7070
CMD ["npm","start"]
