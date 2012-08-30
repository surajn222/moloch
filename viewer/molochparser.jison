/* lexical grammar */
%lex

%options flex
%%

\s+                   /* skip whitespace */
[0-9]+\b                  return 'NUMBER'
([0-9]{1,3})?("."[0-9]{1,3})?("."[0-9]{1,3})?("."[0-9]{1,3})?("/"[0-9]{1,2})?(":"[0-9]{1,5})?\b return 'IPMATCH'
"bytes"                   return 'bytes'
"databytes"               return 'databytes'
"packets"                 return 'packets'
"protocol"                return 'protocol'
"port.src"                return 'port.src'
"port.dst"                return 'port.dst'
"port"                    return 'port'
"node"                    return 'node'
"country.src"             return 'country.src'
"country.dst"             return 'country.dst'
"country.xff"             return 'country.xff'
"country"                 return 'country'
"asn.src"                 return 'asn.src'
"asn.dst"                 return 'asn.dst'
"asn.xff"                 return 'asn.xff'
"asn"                     return 'asn'
"ip.src"                  return "ip.src"
"ip.dst"                  return "ip.dst"
"ip.xff"                  return "ip.xff"
"ip"                      return "ip"
"uri"                     return "uri"
"ua"                      return "ua"
"icmp"                    return "icmp"
"tcp"                     return "tcp"
"udp"                     return "udp"
"host"                    return "host"
"header"                  return "header"
"tags"                    return 'tags'
[\w*._:-]+                return 'ID'
\"[^"]+\"                 return 'QUOTEDSTR'
"<="                      return 'lte'
"<"                       return 'lt'
">="                      return 'gte'
">"                       return 'gt'
"!="                      return '!='
"=="                      return '=='
"="                       return '=='
"||"                      return '||'
"|"                       return '||'
"&&"                      return '&&'
"&"                       return '&&'
"("                       return '('
")"                       return ')'
"!"                       return '!'
<<EOF>>                   return 'EOF'
.                         return 'INVALID'

/lex

/* operator associations and precedence */

%left '!'
%left '<' '<=' '>' '>=' '==' '!=' 
%left '||'
%left '&&'
%left UMINUS

%start expressions

%% /* language grammar */

expressions
    : e EOF
        { return $1; }
    ;

LTA : lt  {$$ = 'lt'}
    | lte {$$ = 'lte'}
    ;

GTA : gt  {$$ = 'gt'}
    | gte {$$ = 'gte'}
    ;

GTLT: LTA
    | GTA
    ;

IPNUM: IPMATCH
     | NUMBER
     ;

RANGEFIELD: databytes   {$$ = 'db'}
          | bytes       {$$ = 'by'}
          | packets     {$$ = 'pa'}
          | protocol    {$$ = 'pr'}
          | 'port.src'  {$$ = 'p1'}
          | 'port.dst'  {$$ = 'p2'}
          ;

TERMFIELD  : 'country.src' {$$ = 'g1'}
           | 'country.dst' {$$ = 'g2'}
           | 'country.xff' {$$ = 'gxff'}
           | node          {$$ = 'no'}
           | host          {$$ = 'ho'}
           ;

TEXTFIELD  : 'asn.src'     {$$ = 'as1'}
           | 'asn.dst'     {$$ = 'as2'}
           | 'asn.xff'     {$$ = 'asxff'}
           ;

STR : ID
    | packets
    | bytes
    | protocol
    | port
    | port.src
    | port.dst
    | country
    | country.src
    | country.dst
    | country.xff
    | asn
    | asn.src
    | asn.dst
    | asn.xff
    | QUOTEDSTR
    | node
    | host
    | header
    | icmp
    | tcp
    | udp
    | ip
    | ip.src
    | ip.dst
    | ip.xff
    | uri
    | ua
    ;
 
e
    : e '&&' e
        {$$ = {and: [$1, $3]};}
    | 'uri' '==' STR
        {$$ = {query: {text: {us: {query: $3, type: "phrase", operator: "and"}}}};}
    | 'uri' '!=' STR
        {$$ = {not: {query: {text: {us: {query: $3, type: "phrase", operator: "and"}}}}};}
    | 'ua' '==' STR
        {$$ = {query: {text: {ua: {query: $3, type: "phrase", operator: "and"}}}};}
    | 'ua' '!=' STR
        {$$ = {not: {query: {text: {ua: {query: $3, type: "phrase", operator: "and"}}}}};}
    | e '||' e
        {$$ = {or: [$1, $3]};}
    | '!' e %prec UMINUS
        {$$ = {not: $2};}
    | '-' e %prec UMINUS
        {$$ = -$2;}
    | '(' e ')'
        {$$ = $2;}
    | protocol '==' 'icmp'
        {$$ = {term: {pr: 1}};}
    | protocol '==' 'tcp'
        {$$ = {term: {pr: 6}};}
    | protocol '==' 'udp'
        {$$ = {term: {pr: 17}};}
    | RANGEFIELD GTLT NUMBER
        {$$ = {range: {}};
         $$.range[$1] = {};
         $$.range[$1][$2] = $3;}
    | RANGEFIELD '==' NUMBER
        {$$ = {term: {}};
         $$.term[$1] = $3;}
    | RANGEFIELD '!=' NUMBER
        {$$ = {not: {term: {}}};
         $$.not.term[$1] = $3;}
    | 'port' GTLT NUMBER
        {$$ = {or: [{range: {p1: {}}}, {range: {p2: {}}}]};
         $$.or[0].range.p1[$2] = $3;
         $$.or[1].range.p2[$2] = $3;}
    | TERMFIELD '!=' STR
        { var str = stripQuotes($3).toLowerCase();
          if (str.indexOf("*") !== -1) {
            $$ = {not: {query: {wildcard: {}}}};
            $$.not.query.wildcard[$1] = str;
          } else {
            $$ = {not: {term: {}}};
            $$.not.term[$1] = str;
          }
        }
    | TERMFIELD '==' STR
        { var str = stripQuotes($3).toLowerCase();
          if (str.indexOf("*") !== -1) {
            $$ = {query: {wildcard: {}}};
            $$.query.wildcard[$1] = str;
          } else {
            $$ = {term: {}};
            $$.term[$1] = str;
          }
        }
    | TEXTFIELD '!=' STR
        { var str = stripQuotes($3).toLowerCase();
          if (str.indexOf("*") !== -1) {
            $$ = {not: {query: {wildcard: {}}}};
            $$.not.query.wildcard[$1] = str;
          } else {
            $$ = {not: {term: {}}};
            $$.not.term[$1] = str;
          }
        }
    | TEXTFIELD '==' STR
        { var str = stripQuotes($3).toLowerCase();
          if (str.indexOf("*") !== -1) {
            $$ = {query: {wildcard: {}}};
            $$.query.wildcard[$1] = str;
          } else {
            $$ = {query: {text: {}}};
            $$.query.text[$1] = {query: str, type: "phrase", operator: "and"}
          }
        }
    | 'port' '==' NUMBER
        {$$ = {or: [{term: {p1: $3}}, {term: {p2: $3}}]};}
    | 'port' '!=' NUMBER
        {$$ = {not: {or: [{term: {p1: $3}}, {term: {p2: $3}}]}};}
    | 'ip' '==' IPNUM
        {$$ = parseIpPort($3,0);}
    | 'ip' '!=' IPNUM
        {$$ = {not: parseIpPort($3,0)};}
    | 'ip.src' '==' IPNUM
        {$$ = parseIpPort($3,1);}
    | 'ip.src' '!=' IPNUM
        {$$ = {not: parseIpPort($3,1)};}
    | 'ip.dst' '==' IPNUM
        {$$ = parseIpPort($3,2);}
    | 'ip.dst' '!=' IPNUM
        {$$ = {not: parseIpPort($3,2)};}
    | 'ip.xff' '==' IPNUM
        {$$ = parseIpPort($3,3);}
    | 'ip.xff' '!=' IPNUM
        {$$ = {not: parseIpPort($3,3)};}
    | tags '==' STR
        { var tag = stripQuotes($3);
          $$ = {term: {ta: tag}};
        }
    | tags '!=' STR
        { var tag = stripQuotes($3);
          $$ = {not: {term: {ta: tag}}};
        }
    | header '==' STR
        { var tag = stripQuotes($3);
          $$ = {term: {hh: tag}};
        }
    | header '!=' STR
        { var tag = stripQuotes($3);
          $$ = {not: {term: {hh: tag}}};
        }
    | country '==' STR 
        { var str = stripQuotes($3).toUpperCase();
          if (str.indexOf("*") !== -1) {
            $$ = {or: [{query: {wildcard: {g1: str}}}, {query: {wildcard: {g2: str}}}, {query: {wildcard: {gxff: str}}}]};
          } else {
            $$ = {or: [{term: {g1: str}}, {term: {g2: str}}, {term: {gxff: str}}]};
          }
        }
    | country '!=' STR 
        { var str = stripQuotes($3).toUpperCase();
          if (str.indexOf("*") !== -1) {
            $$ = {not: {or: [{query: {wildcard: {g1: str}}}, {query: {wildcard: {g2: str}}}, {query: {wildcard: {gxff: str}}}]}};
          } else {
            $$ = {not: {or: [{term: {g1: str}}, {term: {g2: str}}, {term: {gxff: str}}]}};
          }
        }
    | asn '==' STR 
        { var str = stripQuotes($3).toLowerCase();
          if (str.indexOf("*") !== -1) {
            $$ = {or: [{query: {wildcard: {as1: str}}}, {query: {wildcard: {as2: str}}}, {query: {wildcard: {asxff: str}}}]};
          } else {
            $$ = {or: [{query: {text: {as1:   {query: str, type: "phrase", operator: "and"}}}}, 
                       {query: {text: {as2:   {query: str, type: "phrase", operator: "and"}}}}, 
                       {query: {text: {asxff: {query: str, type: "phrase", operator: "and"}}}}
                      ]
                 };
          }
        }
    | asn '!=' STR 
        { var str = stripQuotes($3).toLowerCase();
          if (str.indexOf("*") !== -1) {
            $$ = {not: {or: [{query: {wildcard: {as1: str}}}, {query: {wildcard: {as2: str}}}, {query: {wildcard: {asxff: str}}}]}};
          } else {
            $$ = {not: {or: [{query: {text: {as1:   {query: str, type: "phrase", operator: "and"}}}}, 
                             {query: {text: {as2:   {query: str, type: "phrase", operator: "and"}}}}, 
                             {query: {text: {asxff: {query: str, type: "phrase", operator: "and"}}}}
                            ]
                 }};
          }
        }
    ;
%%
function parseIpPort(ipPortStr, which) {
  ipPortStr = ipPortStr.trim();
  // Support '10.10.10/16:4321'

  var ip1 = -1, ip2 = -1;
  var colons = ipPortStr.split(':');
  var slash = colons[0].split('/');
  var dots = slash[0].split('.');
  var port = -1;
  if (colons[1]) {
    port = parseInt(colons[1], 10);
  }

  if (dots.length === 4) {
    ip1 = ip2 = (parseInt(dots[0], 10) << 24) | (parseInt(dots[1], 10) << 16) | (parseInt(dots[2], 10) << 8) | parseInt(dots[3], 10);
  } else if (dots.length === 3) {
    ip1 = (parseInt(dots[0], 10) << 24) | (parseInt(dots[1], 10) << 16) | (parseInt(dots[2], 10) << 8);
    ip2 = (parseInt(dots[0], 10) << 24) | (parseInt(dots[1], 10) << 16) | (parseInt(dots[2], 10) << 8) | 255;
  } else if (dots.length === 2) {
    ip1 = (parseInt(dots[0], 10) << 24) | (parseInt(dots[1], 10) << 16);
    ip2 = (parseInt(dots[0], 10) << 24) | (parseInt(dots[1], 10) << 16) | (255 << 8) | 255;
  } else if (dots.length === 1 && dots[0].length > 0) {
    ip1 = (parseInt(dots[0], 10) << 24);
    ip2 = (parseInt(dots[0], 10) << 24) | (255 << 16) | (255 << 8) | 255;
  }

  // Can't shift by 32 bits in javascript, who knew!
  if (slash[1] && slash[1] !== '32') {
     var s = parseInt(slash[1], 10);
     ip1 = ip1 & (0xffffffff << (32 - s));
     ip2 = ip2 | (0xffffffff >>> s);
  }

  var t1 = {and: []};
  var t2 = {and: []};
  var xff;

  if (ip1 !== -1) {
    if (ip1 === ip2) {
        t1  = {term: {a1: ip1>>>0}};
        t2  = {term: {a2: ip1>>>0}};
        xff = {term: {xff: ip1>>>0}};
    } else {
        t1.and.push({range: {a1: {from: ip1>>>0, to: ip2>>>0}}});
        t2.and.push({range: {a2: {from: ip1>>>0, to: ip2>>>0}}});
        xff =  {range: {xff: {from: ip1>>>0, to: ip2>>>0}}};
    }
  }

  if (port !== -1) {
    t1.and.push({term: {p1: port}});
    t2.and.push({term: {p2: port}});
  }

  switch(which) {
  case 0:
    return {or: [t1, t2, xff]};
  case 1:
    return t1;
  case 2:
    return t2;
  case 3:
    return xff;
  }
}

function stripQuotes (str) {
  if (str[0] === "\"") {
    str =  str.substring(1, str.length-1);
  }
  return str;
}