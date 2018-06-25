/**
 * Sends a question submitted from HTML question form.
 *
 * 1. Send question function validates and parses request created by
 *    submitting a form.
 * 2. Send email function calls Mailgun API with data from previous
 *    step. It also reads response from Mailgun.
 * 3. Check Mailgun response function checks whether response from
 *    previous step was successful and finishes.
 *
 * If there’s a user error, a HTTP redirect response to HTML question
 * form is generated.
 *
 * Configuration is via environment variable:
 *
 * - QUESTION_FORM_URL: URL to HTML question form
 * - QUESTION_FORM_FROM: email address from which question will be
 *   sent
 * - QUESTION_FORM_TO: email address to which question will be
 *   delivered
 * - QUESTION_FORM_SUBJECT: subject of email with question
 * - QUESTION_FORM_HONEYPOT: honeypot field for bots
 * - MAILGUN_DOMAIN: Mailgun domain used to send emails
 * - MAILGUN_API_KEY: Mailgun API key
 */

const https = require("https")
const querystring = require("querystring")
const { URL } = require("url")

const MAILGUN_URL = Object.freeze(new URL("https://api.mailgun.net/v3"))

/** @typedef {function(Error=,Object=)} */
var NetlifyCallback

/**
 * Return just type and subtype from Content-Type HTTP header value.
 *
 * @param {string|undefined} headerValue
 * @return {string}
 */
function parseContentType(headerValue) {
  return (headerValue || "").split(/;\s+/, 2)[0]
}

/**
 * Call callback so that it redirects to question form URL.
 *
 * Optional code can be specified. This code is set as a fragment part
 * of the redirect location.
 *
 * @param {!NetlifyCallback} callback
 * @param {string=} code
 */
function redir(callback, code) {
  callback(null, {
    "statusCode": 303,
    "headers": {
      "Location": process.env["QUESTION_FORM_URL"] +
	(code ? `#${code}` : "")
    },
    "body": ""
  })
}

/**
 * Parses and validates event triggered by question form submission.
 *
 * The function ends with a call to {@link sendEmail}.
 *
 * @param {!Object} event
 * @param {!Object} context
 * @param {!NetlifyCallback} callback
 */
function sendQuestion(event, context, callback) {
  if (event["httpMethod"] !== "POST") {
    return callback(
      new Error(`Unexpected HTTP method "${event["httpMethod"]}"`)
    )
  }
  if (parseContentType(event["headers"]["content-type"]) !==
      "application/x-www-form-urlencoded") {
    return callback(
      new Error(`Unexpected content type "${event["headers"]["content-type"]}"`)
    )
  }

  const params = querystring.parse(event["body"])

  if (process.env["QUESTION_FORM_HONEYPOT"] &&
      params[process.env["QUESTION_FORM_HONEYPOT"]]) {
    console.info("Bot trapped in honeypot")
    return callback()
  }

  const errs = []
  if (!params["email"]) errs.push("no-email")
  if (!params["question"]) errs.push("no-question")
  if (errs.length > 0) return redir(callback, errs.join(","))

  sendEmail(
    params["name"] ?
      `"${params["name"]}" <${params["email"]}>` :
      params["email"],
    params["question"],
    callback
  )
}

/**
 * Sends email via Mailgun API.
 *
 * The function runtime ends with a call to {@link
 * checkMailgunResponse}.
 *
 * @param {string} replyTo
 * @param {string} text
 * @param {!NetlifyCallback} callback
 */
function sendEmail(replyTo, text, callback) {
  const data = querystring.stringify({
    from: process.env["QUESTION_FORM_FROM"],
    to: process.env["QUESTION_FORM_TO"],
    subject: process.env["QUESTION_FORM_SUBJECT"],
    "h:Reply-To": replyTo,
    text: text
  })

  const req = https.request({
    method: "POST",
    hostname: MAILGUN_URL.hostname,
    path: `${MAILGUN_URL.pathname}/${process.env["MAILGUN_DOMAIN"]}/messages`,
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "Content-Length": Buffer.byteLength(data)
    },
    auth: `api:${process.env["MAILGUN_API_KEY"]}`
  }, (res) => {
    var body = ""
    res.setEncoding("utf8")
    res.on("data", chunk => body += chunk)
    res.on("end", () => checkMailgunResponse(res, body, callback))
  })
  req.on("error", (e) => {
    console.error("Error while sending email via Mailgun:", e)
    redir(callback, "fail")
  })
  req.write(data)
  req.end()
}

/**
 * Check response from Mailgun API after sending a message.
 *
 * @param {!https.IncomingMessage} res
 * @param {string} body
 * @param {!NetlifyCallback} callback
 */
function checkMailgunResponse(res, body, callback) {
  if (res.statusCode !== 200) {
    console.error("Error response from Mailgun:", body)
    return redir(callback, "fail")
  }

  redir(callback, "sent")
}

exports.handler = sendQuestion
