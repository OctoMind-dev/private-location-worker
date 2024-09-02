import fastify from 'fastify';
import ky from 'ky';

// logger
var log = console.log;

console.log = function(args: any){
  log.apply(console, [new Date().toISOString()].concat(args));
};

const server = fastify();

type RpcCall = {
  version: string;
  op: string;
  content: object;
}

type RpcCallResponse = {
  reject?: boolean;
  reject_reason?: string;
  unchange?: boolean;
  content?: object;
}

type Login = {
  user: string;
  metas: Record<string, string>;
}

type Proxy = {
  user: {
    user: string;
    metas: Record<string, string>;
  };
  proxy_name: string;
  localIP?: string;
  remote_port?: number;
}

type Conf = {
  name: string;
  type: string;
  localIP: string;
  plugin: string | null;
  remotePort: number;
};

type ProxyInfo = {
  name: string;
  conf: Conf;
}

const PROCEED: RpcCallResponse = { reject: false, unchange: true };
enum ProxyState {
  CLOSED = 0,
  OPEN = 1,
}

const octomindUrl = process.env.BASE_URL || 'http://localhost:8000'

const endpoint = `${octomindUrl}/api/apiKey/v2/plw`;

const octoClient = ky.create({
	headers: {
		"x-api-key": process.env.API_KEY || 'dummykey'
	}
});

// for new proxy and close proxy we use the user / proxy name and the apikey to update the state in octomind
//

async function updateProxyState(
  proxy: Proxy,
  state: ProxyState
): Promise<void> {
  //throw new Error('Function not implemented.');
  // call octo platform to update proxy state
  console.log("updateProxyState", proxy, state);
  const res = await octoClient.post(endpoint, {json: {...proxy, state}}).json();
  console.log(JSON.stringify(res,null,2));
}

function makeBasicAuthHeader(user: string, password: string)
{
    const token = user + ":" + password;
    const buf = Buffer.from(token);
    const hash = buf.toString('base64'); 
    return "Basic " + hash;
}

const localClient = ky.create({
	headers: {
		Authorization: makeBasicAuthHeader('admin','aWKF58f3wQgSSMzcNLoYexYyp3y9QsDG6')
	}
});

async function handleCloseProxy(p: Proxy): Promise<RpcCallResponse> {
  await updateProxyState(p, ProxyState.CLOSED);
  return PROCEED;
}

async function updateProxy(p: Proxy) : Promise<void> {
  const proxyInfo = await localClient.get(`http://localhost:7500/api/proxy/tcp/${p.proxy_name}`).json<ProxyInfo>();
  console.log(JSON.stringify(proxyInfo,null,2));
  p.remote_port = proxyInfo.conf.remotePort;
  p.localIP = proxyInfo.conf.localIP;
  await updateProxyState(p, ProxyState.OPEN);
}

async function handleNewProxy(p: Proxy): Promise<RpcCallResponse> {
  // delay to local info call until the connection is established
  setTimeout( async() =>await updateProxy(p),1000);
  return PROCEED;
}

async function handleLogin(loginRequest: Login): Promise<RpcCallResponse> {
  const res = await octoClient.post(endpoint, {json: {...loginRequest}}).json();
  console.log(JSON.stringify(res,null,2));

  if (loginRequest.user === 'foo3') {
    return {
      reject: true,
      reject_reason: 'invalid user: foo3 not allowed',
    };
  } else {
    return PROCEED;
  }
}

server.post('/handler', async (request, reply) => {
  console.log(JSON.stringify(request.body, null, 2));
  const call = request.body as RpcCall;
  if (call.op === 'Login') {
    return await handleLogin(call.content as Login);
  } else if (call.op === 'NewProxy') {
    return await handleNewProxy(call.content as Proxy);
  } else if (call.op === 'CloseProxy') {
    return await handleCloseProxy(call.content as Proxy);
  }
  reply
    .code(409)
    .header('Content-Type', 'application/json; charset=utf-8')
    .send({ message: 'bad request' });
});

server.listen({ port: 9000 }, (err, address) => {
  if (err) {
    console.error(err);
    process.exit(1);
  }
  console.log(`Server listening at ${address}`);
});
