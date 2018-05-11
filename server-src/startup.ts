import * as express from "express";

const app = express();

app.use(express.static("public"));

const PORT_NUMBER = process.env.HTTP_PORT || 3000;

app.listen(PORT_NUMBER);
process.stdout.write(`server listening at port ${PORT_NUMBER}`);
