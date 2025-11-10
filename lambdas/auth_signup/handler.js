const crypto = require("crypto");
const { DynamoDBClient, PutItemCommand } = require("@aws-sdk/client-dynamodb");

const db = new DynamoDBClient({});
const TABLE = process.env.USERS_TABLE;

exports.handler = async (event) => {
  const { email, password } = JSON.parse(event.body || "{}");
  if (!email || !password) return response(400, { error: "email & password required" });

  const salt = crypto.randomBytes(16).toString("hex");
  const pwd_hash = crypto.scryptSync(password, salt, 64).toString("hex");
  const email_hash = crypto.createHash("sha256").update(email.toLowerCase()).digest("hex");
  const user_id = crypto.randomUUID();

  await db.send(
    new PutItemCommand({
      TableName: TABLE,
      Item: {
        user_id: { S: user_id },
        email_hash: { S: email_hash },
        pwd_hash: { S: pwd_hash },
        salt: { S: salt },
        created_at: { S: new Date().toISOString() },
      },
      ConditionExpression: "attribute_not_exists(user_id)",
    })
  );

  return response(201, { user_id });
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
