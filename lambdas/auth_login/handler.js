const crypto = require("crypto");
const jwt = require("jsonwebtoken");
const { DynamoDBClient, QueryCommand } = require("@aws-sdk/client-dynamodb");

const db = new DynamoDBClient({});
const TABLE = process.env.USERS_TABLE;
const SECRET = process.env.JWT_SECRET;

exports.handler = async (event) => {
  const payload = JSON.parse(event.body || "{}");
  const { email, password, user_id } = payload;

  if (!email || !password || !user_id) {
    return response(400, { error: "email, password & user_id required" });
  }

  const email_hash = crypto.createHash("sha256").update(email.toLowerCase()).digest("hex");

  const result = await db.send(
    new QueryCommand({
      TableName: TABLE,
      KeyConditions: {
        user_id: {
          ComparisonOperator: "EQ",
          AttributeValueList: [{ S: user_id }],
        },
      },
      Limit: 1,
    })
  );

  const item = result.Items?.[0];
  if (!item) return response(401, { error: "invalid credentials" });

  const salt = item.salt.S;
  const check = crypto.scryptSync(password, salt, 64).toString("hex");
  if (check !== item.pwd_hash.S || email_hash !== item.email_hash.S) {
    return response(401, { error: "invalid credentials" });
  }

  const token = jwt.sign({ sub: user_id }, SECRET, { algorithm: "HS256", expiresIn: "1h" });
  return response(200, { token });
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
