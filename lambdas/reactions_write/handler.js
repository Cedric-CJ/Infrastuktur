const { DynamoDBClient, PutItemCommand } = require("@aws-sdk/client-dynamodb");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");

const db = new DynamoDBClient({});

exports.handler = async (event) => {
  const SECRET = process.env.JWT_SECRET;
  const REACTIONS = process.env.REACTIONS_TABLE;
  const LOGS = process.env.LOGS_TABLE;

  try {
    const authHeader = event.headers?.authorization || event.headers?.Authorization || "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    const { sub: user_id } = jwt.verify(token, SECRET);

    const { content_id, reaction } = JSON.parse(event.body || "{}");
    if (!content_id || !reaction) return response(400, { error: "content_id & reaction required" });

    const created_at = new Date().toISOString();

    await db.send(
      new PutItemCommand({
        TableName: REACTIONS,
        Item: {
          content_id: { S: content_id },
          user_id: { S: user_id },
          reaction: { S: reaction },
          created_at: { S: created_at },
        },
      })
    );

    await db.send(
      new PutItemCommand({
        TableName: LOGS,
        Item: {
          log_date: { S: created_at.slice(0, 10) },
          log_id: { S: crypto.randomUUID() },
          msg: { S: `reaction by ${user_id}` },
          ttl: { N: `${Math.floor(Date.now() / 1000) + 7 * 24 * 3600}` },
        },
      })
    );

    return response(201, { ok: true });
  } catch (err) {
    console.error(err);
    return response(401, { error: "unauthorized" });
  }
};

const response = (status, body) => ({
  statusCode: status,
  headers: cors(),
  body: JSON.stringify(body),
});

const cors = () => ({
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "*",
});
