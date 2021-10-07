package socket

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"com.todother/DataAccess"
	"com.todother/DataEntity"
	"github.com/gorilla/websocket"
	"github.com/kataras/iris/v12"
	tsgutils "github.com/typa01/go-utils"
)

//运行新客户端连接
func RunWebSocket(app *iris.Application) {

	app.Get("/socket", NewSocketClient) //新客户端来了

}

var upgrader = websocket.Upgrader{
	WriteBufferSize: 10240,
	ReadBufferSize:  10240,
	//允许跨域
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

//客户端map
var Clients = make(map[string]*Client) //User.ConnId得到Client

//客户端
type Client struct {
	Conn      *websocket.Conn            //一个连接,flutter中是channel
	Broadcast chan *BroadcastMessageType //!广播chan
}

//广播
type BroadcastMessageType struct {
	To          string
	Msg         []byte
	MsgType     int
	ContentType int
}

//收到消息
type ReceiveMsgType struct {
	FromUser    string `json:"fromUser"`
	ToUser      string `json:"toUser"`
	Content     string `json:"content"`
	GrpId       string `json:"grpId"`
	ContentType int    `json:"contentType"`
}

//添加到客户端maps
func (c *Client) AddToClients(clients map[string]*websocket.Conn) {
	connId := tsgutils.UUID() //!生成UUID
	clients[connId] = c.Conn  //添加到clients
}

//循环处理消息
func (c *Client) ProcessMsg() {
	for {
		select {
		case data := <-c.Broadcast: //!从chan取出消息
			toClient := Clients[data.To]                                       //ToUser.connId找到toClient
			err := toClient.Conn.WriteMessage(websocket.TextMessage, data.Msg) //发送消息到指定用户
			fmt.Println(data.Msg)
			if err != nil {
				fmt.Println(err)
			}
		default:
			time.Sleep(time.Second * 2) //没有则等待2秒
		}
	}
}

//1 on 1 chat
func (c *Client) ReadIndMessage() {

	for {
		fmt.Println("read msg")
		_, msg, err := c.Conn.ReadMessage() //!读取消息
		fmt.Printf("read in msg ,%s", string(msg))
		if err != nil || len(msg) == 0 {
			fmt.Println(err)
			return
		}
		returnValue := DataEntity.SocketReturnValue{
			CallbackName: "onReceiveMsg", //当收到消息
			JsonResponse: string(msg),    //[]byte to string
		}
		var receiveMsg ReceiveMsgType
		err = json.Unmarshal(msg, &receiveMsg) //[]byte解析成ReceiveMsgType
		if err != nil {
			fmt.Println(err)
			return
		}
		res, err := json.Marshal(&returnValue) //ReceiveMsgType to Json
		if err != nil {
			fmt.Println(err)
		}
		//var user DataEntity.Tbl_User
		user := DataAccess.GetUserInfo(receiveMsg.ToUser)
		//result, err := base64.StdEncoding.DecodeString("this is from server listnere")
		message := BroadcastMessageType{
			To:      *user.ConnId, //!to的connId
			Msg:     res,
			MsgType: websocket.TextMessage, //类型为文本型
		}
		c.Broadcast <- &message //!消息堆到Broadcast chan

	}

}

//新客户端加入
func NewSocketClient(ctx iris.Context) {
	w := ctx.ResponseWriter()
	r := ctx.Request()
	conn, err := upgrader.Upgrade(w, r, nil) //升级协议
	if err != nil {
		fmt.Println(err)
	}
	connId := tsgutils.GUID() //!生成一个唯一id
	newClient := Client{conn, make(chan *BroadcastMessageType)}
	Clients[connId] = &newClient

	go newClient.ReadIndMessage() //!
	go newClient.ProcessMsg()     //!
	returnConn := DataEntity.ReturnConn{ConnId: connId}
	connJson, _ := json.Marshal(&returnConn)
	returnValue := DataEntity.SocketReturnValue{
		CallbackName: "onConn", JsonResponse: string(connJson), //返回ConnId
	}
	resultJson, _ := json.Marshal(returnValue) //返回的json格式
	go DataAccess.UpdateConnId(ctx.URLParam("userId"), connId)
	message := BroadcastMessageType{
		To:      connId,     //发给谁
		Msg:     resultJson, //返回的Json
		MsgType: websocket.TextMessage,
	}
	newClient.Broadcast <- &message //推送到client的Broadcast
}
