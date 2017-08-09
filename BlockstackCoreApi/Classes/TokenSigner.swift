//
//  TokenSigner.swift
//  BlockstackCoreApi
//
//  Created by lsease on 7/13/17.
//

import Foundation
import JavaScriptCore

public class TokenSigner
{
    let context = JSContext()!
    
    // shared instance
    public class func shared() -> TokenSigner {
        
        struct Singleton {
            static let instance = TokenSigner()
        }
        return Singleton.instance
    }
    
    init()
    {
        setupJavascriptContext()
    }
    
    private func setupJavascriptContext()
    {
        let bundlePath = Bundle(for: BlockstackAuth.self).path(forResource: "BlockstackCoreApi", ofType: "bundle")
        if let path = bundlePath,
            let bundle = Bundle(path: path),
            let jsPath = bundle.path(forResource: "jsontokens", ofType: "js"),
            let js =  try? String.init(contentsOfFile: jsPath)
        {
            let loaded = context.evaluateScript(js)
            if loaded?.toBool() == true
            {
                print("Jsontokens-js Load successful")
            }
        }
    }
    
    public func sign(tokenPayload : [String: Any], privateKey : String) -> String?
    {
        //set private key variable
        context.evaluateScript("var rawPrivateKey = '\(privateKey)'")
        
        //get our token signer object
        context.evaluateScript("var tokenSigner = new TokenSigner('ES256k',rawPrivateKey)")
        
        //set our payload to js context
        context.setObject(tokenPayload, forKeyedSubscript: "tokenPayload" as (NSCopying & NSObjectProtocol)!)
        
        //evaluate / sign
        let result = context.evaluateScript("tokenSigner.sign(tokenPayload);")
        
        return result?.toString()
    }
    
    public func decodeToken(_ token : String) -> [AnyHashable : Any]?
    {
        let method = context.objectForKeyedSubscript("decodeToken")
        let result = method!.call(withArguments: [token])
        return result?.toDictionary()
    }
    
    
    public func createUnsecuredToken(tokenPayload : [String: Any]) -> String?
    {
        //set our payload to js context
        context.setObject(tokenPayload, forKeyedSubscript: "tokenPayload" as (NSCopying & NSObjectProtocol)!)
        
        let result = context.evaluateScript("createUnsecuredToken(tokenPayload);")
        return result?.toString()
    }
    
    public func verify(token : String, publicKey : String) -> Bool
    {
        //set private key variable
        context.evaluateScript("var rawPublicKey = '\(publicKey)'")
        
        //get our token signer object
        context.evaluateScript("var tokenVerifier = new TokenVerifier('ES256k',rawPublicKey)")
        
        //set our payload to js context
        context.evaluateScript("var token = '\(token)'")
        
        //evaluate / sign
        let result = context.evaluateScript("tokenVerifier.verify(token);")
        
        return result?.toBool() ?? false
    }
    
    
    //MARK: Unsigned Encoding
    public static func signUnsecured(requestData : [String : Any]) -> String?
    {
        if let jsonString = requestData.jsonString()
        {
            return signUnsecuredString(requestString: jsonString)
        }
        
        return nil
    }
    
    public static func signUnsecuredData(requestData : Data) -> String?
    {
        if let jsonString = String(data: requestData, encoding : .utf8)
        {
            return signUnsecuredString(requestString: jsonString)
        }
        
        return nil
    }
    
    public static func signUnsecuredString(requestString : String) -> String?
    {
        //TODO: Implement
        return requestString.base64Encoded()
    }
    
    //MARK: Signed Encoding
    public static func sign(requestData : [String : Any], privateKey : String) -> String?
    {
        if let jsonString = requestData.jsonString()
        {
            return signString(jsonString: jsonString, privateKey: privateKey)
        }
        
        return nil
        
        //for now return our test token
//        return "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NksifQ.eyJqdGkiOiI0NDkxYjUyNC0yNmY1LTQ5YjctOWRmOC1kMzg1YTc5OTk3NzIiLCJpYXQiOjE1MDAwNDA3NjEsImV4cCI6MTUwMDA0NDM2MSwiaXNzIjoiZGlkOmJ0Yy1hZGRyOjE2aDNnYWRreUJIWThqVUQ1R2VEYVQyOU5taUtpUUpodVkiLCJwdWJsaWNfa2V5cyI6WyIwMzNlMmZjMzJhMzFiOTcyMTg0NDU0YmI2NDUwOTU3MzhlMjJjZjU3NzY3MWY0NjkwMWZhMzZkMzUwMTFjMzgzYjciXSwiZG9tYWluX25hbWUiOiJic2s3Nzc6Ly8iLCJtYW5pZmVzdF91cmkiOiJodHRwczovL3MzLmFtYXpvbmF3cy5jb20vY2FzYS13ZWIvbWFuaWZlc3QuanNvbiIsInJlZGlyZWN0X3VyaSI6ImJzazc3NzovL2F1dGgiLCJzY29wZXMiOlsic3RvcmVfd3JpdGUiXX0.cf8fhI0ZLU-U6tJfFiiLZF1beieLya6mKVVY38MsDFA1kE3IAeuIR8hqOKRcsOUrilaAdhs2nZMOLV8PEGlBUA"
    }
    
    public static func signData(requestData : Data, privateKey : String) -> String?
    {
        
        if let jsonString = String(data: requestData, encoding : .utf8)
        {
            return signString(jsonString: jsonString, privateKey: privateKey)
        }
        
        return nil
    }
    
    public static func signString(jsonString : String, privateKey : String) -> String?
    {
        //TODO: Implement
        //using signing algorithm ES256k
        //create a header with {typ: 'JWT', alg: 'ES256k'}
        //signing input = base64 encoded string representation of header
        //base64 encoded version of the payload
        //separated by a .
        //the last part of the token is a signature generated by:
        //creating a hash of the signing input
        //and signing the hash with the private key
        
        return jsonString.base64Encoded()
    }
    
    //MARK: Decoding
    public static func decode(responseData : String, privateKey: String) -> [String : Any]?
    {
        //TODO: Implement
        //break the string into 3 parts separated by a .
        //base64 decode the header, part 0
        //base64 decode the payload, part 1
        //the 3rd part is the signature
        if let decodedString = responseData.base64Decoded()
        {
            return decodedString.toJsonDictionary()
        }
        return nil
    }
    
    public static func decodeUnsecured(responseData : String) -> [String : Any]?
    {
        //TODO: Implement
        //break the string into 3 parts separated by a .
        //base64 decode the header, part 0
        //base64 decode the payload, part 1
        //the 3rd part is the signature
        
        if let decodedString = responseData.base64Decoded()
        {
            return decodedString.toJsonDictionary()
        }
        return nil
    }
    
    public static func decodeToData(responseData : String, privateKey: String) -> Data?
    {
        //TODO: Implement
        //break the string into 3 parts separated by a .
        //base64 decode the header, part 0
        //base64 decode the payload, part 1
        //the 3rd part is the signature
        if let decodedString = responseData.base64Decoded()
        {
            return decodedString.data(using: .utf8)
        }
        return nil
    }
    
    public static func decodeToDataUnsecured(responseData : String) -> Data?
    {
        //TODO: Implement
        //break the string into 3 parts separated by a .
        //base64 decode the header, part 0
        //base64 decode the payload, part 1
        //the 3rd part is the signature
        
        if let decodedString = responseData.base64Decoded()
        {
            return decodedString.data(using: .utf8)
        }
        return nil
    }
}
