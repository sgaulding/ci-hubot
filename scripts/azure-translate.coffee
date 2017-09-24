# Description:
#   Allows Hubot to know many languages.
#
# Configuration
#   HUBOT_AZURE_CS_KEY - Your Azure Cognitive Services API key
#
# Commands:
#   hubot translate me <phrase> - Searches for a translation for the <phrase> and then prints that bad boy out.
#   hubot translate me from <source> into <target> <phrase> - Translates <phrase> from <source> into <target>. Both <source> and <target> are optional

languages =
  "af": "Afrikaans",
  "sq": "Albanian",
  "ar": "Arabic",
  "az": "Azerbaijani",
  "eu": "Basque",
  "bn": "Bengali",
  "be": "Belarusian",
  "bg": "Bulgarian",
  "ca": "Catalan",
  "zh-CN": "Simplified Chinese",
  "zh-TW": "Traditional Chinese",
  "hr": "Croatian",
  "cs": "Czech",
  "da": "Danish",
  "nl": "Dutch",
  "en": "English",
  "eo": "Esperanto",
  "et": "Estonian",
  "tl": "Filipino",
  "fi": "Finnish",
  "fr": "French",
  "gl": "Galician",
  "ka": "Georgian",
  "de": "German",
  "el": "Greek",
  "gu": "Gujarati",
  "ht": "Haitian Creole",
  "iw": "Hebrew",
  "hi": "Hindi",
  "hu": "Hungarian",
  "is": "Icelandic",
  "id": "Indonesian",
  "ga": "Irish",
  "it": "Italian",
  "ja": "Japanese",
  "kn": "Kannada",
  "ko": "Korean",
  "la": "Latin",
  "lv": "Latvian",
  "lt": "Lithuanian",
  "mk": "Macedonian",
  "ms": "Malay",
  "mt": "Maltese",
  "no": "Norwegian",
  "fa": "Persian",
  "pl": "Polish",
  "pt": "Portuguese",
  "ro": "Romanian",
  "ru": "Russian",
  "sr": "Serbian",
  "sk": "Slovak",
  "sl": "Slovenian",
  "es": "Spanish",
  "sw": "Swahili",
  "sv": "Swedish",
  "ta": "Tamil",
  "te": "Telugu",
  "th": "Thai",
  "tr": "Turkish",
  "uk": "Ukrainian",
  "ur": "Urdu",
  "vi": "Vietnamese",
  "cy": "Welsh",
  "yi": "Yiddish"

getCode = (language, languages) ->
  for code, lang of languages
    return code if lang.toLowerCase() is language.toLowerCase()

getTranslation = (robot, msg, token) ->
  term = "\"#{msg.match[3]?.trim()}\""
  origin = if msg.match[1] isnt undefined then getCode(msg.match[1], languages) else ''
  target = if msg.match[2] isnt undefined then getCode(msg.match[2], languages) else 'en'

  token = "Bearer #{token}"
  console.log('token', token)

  msg.http("https://api.microsofttranslator.com/v2/Http.svc/Translate")
    .header('Authorization', token)
    .query({
      text: term
      from: origin
      to: target
      contentType: 'text/plain'
    }).get() (err, res, body) ->

      console.log('body', body)

      if err
        msg.send "Failed to connect to Azure Cognitive Service"
        robot.emit 'error', err, res
        return

      if body
        {parseString} = require 'xml2js'
        parsed = null
        parseString body, (err, result) ->
          console.log('result', result)
          parsed = result['string']['_']
        if parsed
          if msg.match[2] is undefined
            msg.send ">>>#{term}\n Translates as\n *#{languages[target]}*: #{parsed}"
          else
            msg.send ">>>*#{languages[origin]}*: #{term}\n Translates as\n *#{languages[target]}*: #{parsed}"
      else
        throw new SyntaxError 'Invalid JS code'

translate = (robot, msg, callback) ->
  key = process.env.HUBOT_AZURE_CS_KEY

  http = require("https")

  options = {
    "method": "POST",
    "hostname": "api.cognitive.microsoft.com",
    "port": null,
    "path": "/sts/v1.0/issueToken",
    "headers": {
      "ocp-apim-subscription-key": key,
      "cache-control": "no-cache"
    }
  }

  issueToken = ''

  req = http.request(options, (res) ->
    chunks = [];
    res.on("data", (chunk) -> chunks.push(chunk))
    res.on("end", () ->
      issueToken = Buffer.concat(chunks)
      callback(robot, msg, issueToken)
    )
  )

  req.end()

module.exports = (robot) ->
  language_choices = (language for _, language of languages).sort().join('|')
  pattern = new RegExp('translate(?: me)?' +
    "(?: from (#{language_choices}))?" +
    "(?: (?:in)?to (#{language_choices}))?" +
    '(.*)', 'i')
  robot.respond pattern, (msg) ->
    try
      translate(robot, msg, getTranslation)
    catch err
      msg.send "Failed to parse Azure Cognitive Service response"
      robot.emit 'error', err
