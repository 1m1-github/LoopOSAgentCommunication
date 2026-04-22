module LoopOSAgentCommunication

using ZMQ
using LoopOS: InputPeripheral, OutputPeripheral, listen, @whiletrue
import Base: take!, put!

const CONTEXT = ZMQ.context()
const DEALER = Socket(CONTEXT, DEALER)
setproperty!(DEALER, :routing_id, Sys.username())
const SUB = Socket(CONTEXT, SUB)

function init(group)
    connect(DEALER, "ipc:///router")
    connect(SUB, "ipc:///pub")
    subscribe(SUB, group)
    subscribe(SUB, "∀")
    listen(RECEIVEMESSAGE)
    @async @whiletrue receive(DEALER), @async @whiletrue receive(SUB)
end

function receive(socket)
    frames = ZMQ.recv_multipart(socket)
    to = String(frames[1])
    from = String(frames[2])
    message = String(frames[3])
    put!(RECEIVEMESSAGE, "$from>$to>$message")
end

send(message, to) = send_multipart(DEALER, [to, getproperty(DEALER, :routing_id), message])
struct DirectMessage <: OutputPeripheral end
put!(::DirectMessage, message::String, to::String="Dona") = send(message, to)
struct GroupMessage <: OutputPeripheral end
put!(::GroupMessage, message::String) = send(message, "group")

struct ReceiveMessage <: InputPeripheral
    channel::Channel{String}
end
take!(a::ReceiveMessage) = take!(a.channel)
put!(a::ReceiveMessage, message) = put!(a.channel, message)
const RECEIVEMESSAGE = ReceiveMessage(Channel{String}(Inf))

end
