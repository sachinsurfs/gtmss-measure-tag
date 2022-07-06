___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Quantcast Measure",
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
  },
  "description": "",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "pcode",
    "displayName": "P-Code",
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "label",
    "displayName": "Labels",
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "userId",
    "displayName": "User Id (Optional)",
    "simpleValueType": true,
    "help": "Sending hashed customer identifiers for logged-in users may help improve the accuracy of your audience insights. \n\u003ca href\u003d\"https://help.quantcast.com/hc/en-us/articles/360052329093\"\u003eLearn more.\u003c/a\u003e"
  }
]


___SANDBOXED_JS_FOR_SERVER___

// Imports
const encodeUriComponent = require('encodeUriComponent');
const generateRandom = require('generateRandom');
const getEventData = require('getEventData');
const logToConsole = require('logToConsole');
const sendHttpGet = require('sendHttpGet');
const sendPixelFromBrowser = require('sendPixelFromBrowser');
const getCookieValues = require('getCookieValues');
const setCookie = require('setCookie');
const queryPermission = require('queryPermission');
const returnResponse = require('returnResponse');
const setPixelResponse = require('setPixelResponse');
const sha256Sync = require('sha256Sync');
const computeEffectiveTldPlusOne = require('computeEffectiveTldPlusOne');
const getRemoteAddress = require('getRemoteAddress');
const getTimestamp = require('getTimestamp');
const setResponseHeader = require('setResponseHeader');
const getRequestHeader = require('getRequestHeader');
const getTimestampMillis = require('getTimestampMillis');

// Constants
const FPA_COOKIE = '__qca';
const GA_COOKIE = '__ga';
const MAX_USER_ID = 2147483647;
const COOKIE_EXP_TIME = 33868800;
const USERHASH_TYPE_UNKNOWN = 2;

// Fields
const pcode = data.pcode;
const static_label = data.label;
const uid = data.userId;

// The event name is taken from either the tag's configuration or from the
// event. Configuration data comes into the sandboxed code as a predefined
// variable called 'data'.
const eventName = data.eventName || getEventData('event_name');
const user_agent = getEventData('user_agent');
const x_forwarded_for = getRemoteAddress() || getEventData('ip_override');
const pageLocation = getEventData('page_location');
const pageHostname = computeEffectiveTldPlusOne(pageLocation);
const host = getRequestHeader('host');

const fpaParams = getFpa();
const uhParams = getUh();

// Performs best-effort to retrieve a first-party cookie -
// if '__qca', Quantcast analytics first - party cookie, is present and accessible, we use that
// else if '_ga', Google analytics first - party cookie, is present and accessible, we use that 
// else if client_id, a hashed '_ga' id sent to server, is present, use that
// else generate a random id similar to _qca generation in quantjs
//
// If the __qca cookie is not present, one is set on the server's
// highest-level domain on which you can set a cookie.
// We recommend deploying server-side tagging on a subdomain of your website 
// to improve measure. Learn more -
// https://developers.google.com/tag-platform/tag-manager/server-side/custom-domain
function getFpa() {
  var fpan = 0;
  var fpa = getCookieValues(FPA_COOKIE)[0];
  if (!fpa) {
    fpa = getCookieValues(GA_COOKIE)[0] ||
      getEventData('client_id') ||
      'G0-' + generateRandom(0, MAX_USER_ID) + '-' +  getTimestampMillis;
    // This is not perfect since we don't have information on when _ga cookie was set
    fpan = 1;
    
    setCookie(FPA_COOKIE, fpa, {
    'max-age': COOKIE_EXP_TIME,
    domain: computeEffectiveTldPlusOne(host),
    path: '/',
    httpOnly: false,
    secure: true,
    samesite: 'none'
    });
    
  }
  return 'fpa=' + fpa + ';fpan=' + fpan;
}

// Returns the SHA256-hashed user-provided id id along with the id type. 
function getUh() {
  var uht = USERHASH_TYPE_UNKNOWN;
  var uh = uid? sha256Sync(uid.toLowerCase(), {outputEncoding: 'hex'}) :'';
  return 'uh=' + uh + ';uht=' + uht;
}

var url = 'https://pixel.quantserve.com/pixel;r=' +
    generateRandom(0, MAX_USER_ID) +
    ';source=gtmss;labels=_fp.event.' + encodeUriComponent(eventName) +
    ';a=' + pcode +
    ';url=' + encodeUriComponent(pageLocation) +
    ';d=' + pageHostname +
    uhParams +
    fpaParams +
    ';et=' + getTimestamp();

logToConsole(url);

if(queryPermission('send_pixel_from_browser', url) && sendPixelFromBrowser(url)) {
  logToConsole("sending pixel from browser successful");
  data.gtmOnSuccess();
} else {

  // Construct a server-to-server quantserve pixel
  // with X-Forwarded-For and User-Agent headers 
  // and send via sendHttpGet()
  sendHttpGet(url.replace('_fp.event.','_fp.event.serverside-'), 
              (statusCode, header) => {
    logToConsole(header);
    if (statusCode >= 200 && statusCode < 300) {
      logToConsole("sending pixel from server successful");
      data.gtmOnSuccess();
    } else {
      data.gtmOnFailure();
    }
  }, 
              {
    headers: {
      'X-Forwarded-For': x_forwarded_for,
      'User-Agent': user_agent,
    }, 
    timeout: 500
  });

}  

// Flush response back to browser for setting cookies
returnResponse();


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "all"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_pixel_from_browser",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "specific"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "set_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedCookies",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "name"
                  },
                  {
                    "type": 1,
                    "string": "domain"
                  },
                  {
                    "type": 1,
                    "string": "path"
                  },
                  {
                    "type": 1,
                    "string": "secure"
                  },
                  {
                    "type": 1,
                    "string": "session"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "__qca"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "cookieNames",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "__qca"
              },
              {
                "type": 1,
                "string": "_ga"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "return_response",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queryParameterAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_response",
        "versionId": "1"
      },
      "param": [
        {
          "key": "writeResponseAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "writeHeaderAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 7/6/2022, 9:53:28 AM


