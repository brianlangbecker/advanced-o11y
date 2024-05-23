<?php

namespace App\Controller;

require __DIR__ . '/../../vendor/autoload.php';

use React\EventLoop\Factory as LoopFactory;
use React\Promise\Promise;
use App\OpenTelemetry\HasTraceableTrait;
use App\OpenTelemetry\SdkBuilder;
use OpenTelemetry\API\Signals;
use OpenTelemetry\API\Trace\Propagation\TraceContextPropagator;
use OpenTelemetry\API\Trace\SpanInterface;
use OpenTelemetry\Contrib\Otlp\OtlpHttpTransportFactory;
use OpenTelemetry\Contrib\Otlp\OtlpUtil;
use OpenTelemetry\Contrib\Otlp\SpanExporter;
use OpenTelemetry\SDK\Common\Attribute\Attributes;
use OpenTelemetry\SDK\Common\Configuration\Configuration;
use OpenTelemetry\SDK\Common\Configuration\Variables;
use OpenTelemetry\SDK\Common\Time\ClockFactory;
use OpenTelemetry\SDK\Resource\ResourceInfo;
use OpenTelemetry\SDK\Sdk;
use OpenTelemetry\SDK\Trace\SpanProcessor\BatchSpanProcessor;
use OpenTelemetry\SDK\Trace\TracerProvider;
use OpenTelemetry\SemConv\ResourceAttributes;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\HttpFoundation\Response;




class YearController extends AbstractController
{
    use HasTraceableTrait;


    private TracerProvider $tracerProvider;

    private ?SpanInterface $span, $root, $scope = null;

    #[Route('/year', name: 'app_year')]
    public function index(): Response
    {
        $loop = LoopFactory::create();
        $this->instrumentedNormalAsync($loop);
        $loop->run();

        $message = "The basic instrumenation and async exercise. Go see your OpenTelemetry traces in Honeycomb!";
        return $this->createHtmlResponse($message);

    }

    // This is the async version of doing it the Normal way without helper functions
    public function instrumentedNormalAsync($loop)
    {
        # Setup the exporter, create connection and then build
        $headers = OtlpUtil::getHeaders(\OpenTelemetry\API\Signals::TRACE);
        $transport = (new OtlpHttpTransportFactory())->create(Configuration::getString(Variables::OTEL_EXPORTER_OTLP_ENDPOINT), 'application/x-protobuf', $headers);
        $exporter = new SpanExporter($transport);

        $resource = ResourceInfo::create(Attributes::create([
            ResourceAttributes::SERVICE_NAMESPACE => 'Demo',
            ResourceAttributes::SERVICE_NAME => 'year-php',
        ]));

        $tracerProvider = new TracerProvider(
            spanProcessors: [new BatchSpanProcessor($exporter, ClockFactory::getDefault())],
            resource: $resource,
        );

        Sdk::builder()
            ->setTracerProvider($tracerProvider)
            ->setPropagator(TraceContextPropagator::getInstance())
            ->setAutoShutdown(true)
            ->buildAndRegisterGlobal();

        $tracer = $tracerProvider->getTracer('year-php');

        //Create a root span
        $root = $tracer->spanBuilder('root-async')->startSpan();
        $scope = $root->activate();

        for ($i = 0; $i < 30; $i++) {
            $this->createSpanAsync($loop, $tracer, 'loop-async-' . $i);
        }

        $loop->addTimer(1, function () use ($root, $scope, $tracerProvider) {
            $root->end();
            $scope->detach();
            $tracerProvider->shutdown();
        });
    }

    // This is actually fake async, but it's a good example of how to do it
    private function createSpanAsync($loop, $tracer, $name)
    {
        // Create a span with a random year as an attribute
        $loop->addTimer(.000000000001, function () use ($tracer, $name) {
            $span = $tracer->spanBuilder($name)->startSpan();
            $span->setAttribute('dc.year', $this->getRandomYear());
            $span->end();
        });
    }

    function getRandomYear(): int
    {
        $currentYear = date("Y"); // Get the current year
        usleep(rand(0, 5000)); // Simulate a small delay
        $randomYear = rand(2015, $currentYear); // Get a random year between 2015 and current year
        return $randomYear;
    }

    private function createHtmlResponse(string $message): Response
    {
        // HTML content with styles
        $htmlContent = <<<HTML
<html>
<head>
    <style>
        body {
            background-color: #f0f8ff; /* light blue background */
            color: #333333; /* dark gray text */
            font-family: Arial, sans-serif; /* Set the font */
            margin: 0;
            padding: 20px;
        }
        .message {
            border: 2px solid #007bff; /* blue border */
            padding: 20px;
            border-radius: 5px; /* rounded corners */
            box-shadow: 0 4px 8px rgba(0,0,0,0.1); /* subtle shadow */
            max-width: 600px;
            margin: 40px auto; /* centering */
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="message">
        <p>{$message}</p>
    </div>
</body>
</html>
HTML;

        return new Response($htmlContent, Response::HTTP_OK, ['content-type' => 'text/html']);
    }
}

